const express = require("express");
const router = express.Router();
const pool = require("../config/db");

// Get employees by department for payroll
router.get("/department/:departmentId/employees", async (req, res) => {
  const { departmentId } = req.params;
  
  try {
    const [rows] = await pool.execute(
      `SELECT 
        e.id, 
        e.name, 
        e.designation, 
        e.salary, 
        d.name as department_name,
        -- You can add default working days logic here if needed
        30 as default_working_days,
        0 as default_leave_days
       FROM employees e 
       JOIN departments d ON e.department = d.name 
       WHERE e.isActive = 1 AND d.id = ?`,
      [departmentId]
    );
    
    res.json(rows);
    
  } catch (err) {
    console.error("❌ Department employees error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// Create payroll period
router.post("/periods", async (req, res) => {
  const { period_name, start_date, end_date, period_type } = req.body;

  console.log("=== DEBUG: Received Request Body ===");
  console.log("Full body:", JSON.stringify(req.body, null, 2));
  console.log("period_type value:", period_type);
  console.log("period_type type:", typeof period_type);
  console.log("===================================");

  try {
    const type = period_type && period_type.trim() !== "" ? period_type : "full_month";
    
    console.log("Final type to save:", type);

    const [result] = await pool.execute(
      "INSERT INTO payroll_periods (period_name, start_date, end_date, period_type) VALUES (?, ?, ?, ?)",
      [period_name, start_date, end_date, type]
    );

    // ✅ VERIFY WHAT WAS ACTUALLY SAVED
    const [savedRecord] = await pool.execute(
      "SELECT * FROM payroll_periods WHERE id = ?",
      [result.insertId]
    );
    
    console.log("=== SAVED RECORD ===");
    console.log(JSON.stringify(savedRecord[0], null, 2));
    console.log("====================");

    res.status(201).json({
      id: result.insertId,
      period_name,
      start_date,
      end_date,
      period_type: type,
      saved_record: savedRecord[0], // ✅ Return what was actually saved
      message: "Payroll period created successfully"
    });
  } catch (err) {
    console.error("❌ Create period error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// Generate payroll for department
router.post("/department/:departmentId/generate", async (req, res) => {
  const { departmentId } = req.params;
  const { period_id, employees } = req.body;
  
  const conn = await pool.getConnection();
  
  try {
    await conn.beginTransaction();
    
    // Process each employee in the department
    for (const emp of employees) {
      const { 
        employee_id, 
        basic_salary, 
        allowances, 
        deductions, 
        net_salary, 
        components,
        working_days = 0,
        leave_days = 0,
        daily_rate = 0,
        working_salary = 0,
        leave_salary = 0
      } = emp;
      
      // Insert payroll record with new fields
      const [payrollResult] = await conn.execute(
        `INSERT INTO employee_payroll 
         (employee_id, period_id, department_id, basic_salary, allowances, 
          deductions, net_salary, working_days, leave_days, daily_rate, 
          working_salary, leave_salary) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          employee_id, 
          period_id, 
          departmentId, 
          basic_salary, 
          allowances, 
          deductions, 
          net_salary,
          working_days,
          leave_days,
          daily_rate,
          working_salary,
          leave_salary
        ]
      );
      
      const payrollId = payrollResult.insertId;
      
      // Insert payroll components
      for (const comp of components) {
        await conn.execute(
          `INSERT INTO payroll_components 
           (payroll_id, component_type, component_name, amount) 
           VALUES (?, ?, ?, ?)`,
          [payrollId, comp.type, comp.name, comp.amount]
        );
      }
    }
    
    await conn.commit();
    
    res.status(201).json({ 
      message: "Payroll generated successfully", 
      employees_processed: employees.length 
    });
    
  } catch (err) {
    await conn.rollback();
    console.error("❌ Generate payroll error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  } finally {
    conn.release();
  }
});

// Get payroll by department and period
router.get("/department/:departmentId/period/:periodId", async (req, res) => {
  const { departmentId, periodId } = req.params;
  
  try {
    const [rows] = await pool.execute(
      `SELECT 
        ep.*, 
        e.name as employee_name, 
        e.designation, 
        e.id_card_number,
        p.period_name, 
        p.start_date, 
        p.end_date,
        p.period_type
       FROM employee_payroll ep
       JOIN employees e ON ep.employee_id = e.id
       JOIN payroll_periods p ON ep.period_id = p.id
       WHERE ep.department_id = ? AND ep.period_id = ?`,
      [departmentId, periodId]
    );
    
    // Get components for each payroll
    for (let payroll of rows) {
      const [components] = await pool.execute(
        "SELECT * FROM payroll_components WHERE payroll_id = ?",
        [payroll.id]
      );
      payroll.components = components;
    }
    
    res.json(rows);
    
  } catch (err) {
    console.error("❌ Get payroll error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// Generate payslip PDF data
router.get("/payslip/:payrollId", async (req, res) => {
  const { payrollId } = req.params;
  
  try {
    const [payrollData] = await pool.execute(
      `SELECT 
        ep.*, 
        e.name as employee_name, 
        e.designation, 
        e.id_card_number,
        d.name as department_name, 
        p.period_name, 
        p.start_date, 
        p.end_date,
        p.period_type
       FROM employee_payroll ep
       JOIN employees e ON ep.employee_id = e.id
       JOIN departments d ON ep.department_id = d.id
       JOIN payroll_periods p ON ep.period_id = p.id
       WHERE ep.id = ?`,
      [payrollId]
    );
    
    if (payrollData.length === 0) {
      return res.status(404).json({ error: "Payroll record not found" });
    }
    
    const [components] = await pool.execute(
      "SELECT * FROM payroll_components WHERE payroll_id = ?",
      [payrollId]
    );
    
    const payslipData = {
      ...payrollData[0],
      components: components
    };
    
    res.json(payslipData);
    
  } catch (err) {
    console.error("❌ Payslip error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// Get all payroll periods
router.get("/periods", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT * FROM payroll_periods ORDER BY start_date DESC"
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Periods error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get employee leave data for a period
router.get("/employee/:employeeId/leaves/:periodId", async (req, res) => {
  const { employeeId, periodId } = req.params;
  
  try {
    // This assumes you have a leaves table in your database
    const [leaveData] = await pool.execute(
      `SELECT 
        COALESCE(SUM(leave_days), 0) as total_leave_days,
        COUNT(*) as leave_records
       FROM employee_leaves 
       WHERE employee_id = ? AND period_id = ? AND status = 'approved'`,
      [employeeId, periodId]
    );
    
    res.json({
      employee_id: parseInt(employeeId),
      period_id: parseInt(periodId),
      total_leave_days: leaveData[0]?.total_leave_days || 0,
      leave_records: leaveData[0]?.leave_records || 0
    });
    
  } catch (err) {
    console.error("❌ Get employee leaves error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

module.exports = router;