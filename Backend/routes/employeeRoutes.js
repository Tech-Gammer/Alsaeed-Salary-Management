// routes/employees.js
const express = require('express');
const router = express.Router();
const pool = require("../config/db");

// Create Employee
router.post("/", async (req, res) => {
  const {
    registerDate, name, fatherName, age, education,
    designation, department, salary, reference,
    idCardNumber, address, phoneNumber
  } = req.body;

  try {
    const [result] = await pool.execute(
      `INSERT INTO employees
      (registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber]
    );

    const insertedId = result.insertId;
    res.status(201).json({ id: insertedId, ...req.body });
  } catch (err) {
    console.error("❌ Insert Error:", err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get Employees (with optional active filter)
router.get("/", async (req, res) => {
  try {
    let query = "SELECT * FROM employees";
    let params = [];

    if (req.query.active) {
      query += " WHERE isActive = ?";
      params.push(req.query.active);
    }

    query += " ORDER BY registerDate DESC";

    const [rows] = await pool.execute(query, params);
    res.json(rows);
  } catch (err) {
    console.error("❌ Fetch Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});


// Count Active Employees
router.get("/count", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT COUNT(*) AS count FROM employees WHERE isActive = 1"
    );
    res.json({ count: rows[0].count });
  } catch (err) {
    console.error("❌ Count Fetch Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});


// Get Departments
router.get("/departments", async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT DISTINCT department AS name FROM employees');
    res.json(rows);
  } catch (err) {
    console.error("❌ Department Fetch Error:", err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get Single Employee by ID
router.get("/:id", async (req, res) => {
  try {
    const [rows] = await pool.execute("SELECT * FROM employees WHERE id = ?", [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }
    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Single Employee Fetch Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Update Employee
router.put("/:id", async (req, res) => {
  const {
    registerDate, name, fatherName, age, education,
    designation, department, salary, reference,
    idCardNumber, address, phoneNumber
  } = req.body;

  try {
    const [result] = await pool.execute(
      `UPDATE employees 
       SET registerDate=?, name=?, fatherName=?, age=?, education=?, designation=?, 
           department=?, salary=?, reference=?, idCardNumber=?, address=?, phoneNumber=? 
       WHERE id = ?`,
      [registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber, req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ id: req.params.id, ...req.body });
  } catch (err) {
    console.error("❌ Update Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Delete Employee
router.delete("/:id", async (req, res) => {
  try {
    const [result] = await pool.execute(
      "DELETE FROM employees WHERE id = ?",
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ message: "Employee deleted successfully", id: req.params.id });
  } catch (err) {
    console.error("❌ Delete Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Add Expense for Employee
router.post("/:id/expenses", async (req, res) => {
  const { description, amount, expenseDate } = req.body;

  try {
    const [result] = await pool.execute(
      `INSERT INTO employee_expenses (employeeId, description, amount, expenseDate)
       VALUES (?, ?, ?, ?)`,
      [req.params.id, description, amount, expenseDate]
    );

    res.status(201).json({ 
      id: result.insertId, 
      employeeId: req.params.id, 
      description, 
      amount, 
      expenseDate 
    });
  } catch (err) {
    console.error("❌ Expense Insert Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get All Expenses for an Employee
router.get("/:id/expenses", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT * FROM employee_expenses WHERE employeeId = ? ORDER BY expenseDate DESC",
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Expense Fetch Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Deactivate Employee
router.put("/:id/deactivate", async (req, res) => {
  try {
    const [result] = await pool.execute(
      "UPDATE employees SET isActive = 0 WHERE id = ?",
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ message: "Employee deactivated successfully", id: req.params.id });
  } catch (err) {
    console.error("❌ Deactivate Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Reactivate Employee
router.put("/:id/activate", async (req, res) => {
  try {
    const [result] = await pool.execute(
      "UPDATE employees SET isActive = 1 WHERE id = ?",
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ message: "Employee activated successfully", id: req.params.id });
  } catch (err) {
    console.error("❌ Activate Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Add Loan for Employee
router.post("/:id/loans", async (req, res) => {
  try {
    const { amount, loanDate, description } = req.body;
    if (!amount || !loanDate) {
      return res.status(400).json({ error: "Amount and loanDate are required" });
    }

    const [result] = await pool.execute(
      "INSERT INTO employee_loans (employeeId, amount, loanDate, description) VALUES (?, ?, ?, ?)",
      [req.params.id, amount, loanDate, description || ""]
    );

    res.status(201).json({ message: "Loan added successfully", id: result.insertId });
  } catch (err) {
    console.error("❌ Loan Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get all loans for an employee
router.get("/:id/loans", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT * FROM employee_loans WHERE employeeId = ? ORDER BY loanDate DESC",
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Fetch Loan Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Replace Employee
router.post("/:id/replace", async (req, res) => {
  const oldEmployeeId = req.params.id;
  const { 
    registerDate, name, fatherName, age, education,
    designation, department, salary, reference,
    idCardNumber, address, phoneNumber, reason 
  } = req.body;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Create new employee
    const [insertResult] = await conn.execute(
      `INSERT INTO employees
      (registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber, isActive)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)`,
      [registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber]
    );

    const newEmployeeId = insertResult.insertId;

    // 2. Deactivate old employee
    await conn.execute(
      "UPDATE employees SET isActive = 0 WHERE id = ?",
      [oldEmployeeId]
    );

    // 3. Track replacement
    await conn.execute(
      `INSERT INTO employee_replacements (oldEmployeeId, newEmployeeId, reason, replacementDate)
       VALUES (?, ?, ?, CURDATE())`,
      [oldEmployeeId, newEmployeeId, reason || null]
    );

    await conn.commit();

    res.status(201).json({
      message: "Employee replaced successfully",
      oldEmployeeId,
      newEmployeeId,
    });
  } catch (err) {
    await conn.rollback();
    console.error("❌ Replace Employee Error:", err);
    res.status(500).json({ error: "Database error" });
  } finally {
    conn.release();
  }
});

// Get replacement history
router.get("/:id/replacements", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT er.*, e1.name AS oldEmployeeName, e2.name AS newEmployeeName
       FROM employee_replacements er
       JOIN employees e1 ON er.oldEmployeeId = e1.id
       JOIN employees e2 ON er.newEmployeeId = e2.id
       WHERE er.oldEmployeeId = ? OR er.newEmployeeId = ?
       ORDER BY er.replacementDate DESC`,
      [req.params.id, req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Replacement History Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get complete replacement chain for an employee
router.get("/:id/replacement-chain", async (req, res) => {
  try {
    const employeeId = req.params.id;
    
    // First, find the starting point of the chain (the original employee)
    const [startingPoint] = await pool.execute(
      `WITH RECURSIVE replacement_chain AS (
        SELECT er.id, er.oldEmployeeId, er.newEmployeeId, er.reason, 
               er.replacementDate, e1.name AS oldEmployeeName, e2.name AS newEmployeeName,
               0 as depth
        FROM employee_replacements er
        JOIN employees e1 ON er.oldEmployeeId = e1.id
        JOIN employees e2 ON er.newEmployeeId = e2.id
        WHERE er.newEmployeeId = ?
        
        UNION ALL
        
        SELECT er.id, er.oldEmployeeId, er.newEmployeeId, er.reason, 
               er.replacementDate, e1.name AS oldEmployeeName, e2.name AS newEmployeeName,
               rc.depth + 1 as depth
        FROM employee_replacements er
        JOIN employees e1 ON er.oldEmployeeId = e1.id
        JOIN employees e2 ON er.newEmployeeId = e2.id
        JOIN replacement_chain rc ON er.newEmployeeId = rc.oldEmployeeId
      )
      SELECT * FROM replacement_chain ORDER BY depth DESC`,
      [employeeId]
    );

    // If no chain found, try finding replacements where this employee was the old employee
    if (startingPoint.length === 0) {
      const [replacements] = await pool.execute(
        `SELECT er.id, er.oldEmployeeId, er.newEmployeeId, er.reason, 
                er.replacementDate, e1.name AS oldEmployeeName, e2.name AS newEmployeeName
         FROM employee_replacements er
         JOIN employees e1 ON er.oldEmployeeId = e1.id
         JOIN employees e2 ON er.newEmployeeId = e2.id
         WHERE er.oldEmployeeId = ? OR er.newEmployeeId = ?
         ORDER BY er.replacementDate ASC`,
        [employeeId, employeeId]
      );
      res.json(replacements);
    } else {
      res.json(startingPoint);
    }
  } catch (err) {
    console.error("❌ Replacement Chain Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get latest replacement record for an employee
router.get("/:id/latest-replacement", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT er.*, e1.name AS oldEmployeeName, e2.name AS newEmployeeName
       FROM employee_replacements er
       JOIN employees e1 ON er.oldEmployeeId = e1.id
       JOIN employees e2 ON er.newEmployeeId = e2.id
       WHERE er.oldEmployeeId = ? OR er.newEmployeeId = ?
       ORDER BY er.replacementDate DESC
       LIMIT 1`,
      [req.params.id, req.params.id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: "No replacement history found" });
    }
    
    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Latest Replacement Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Get adjacent replacements in the chain
router.get("/replacements/:id/adjacent", async (req, res) => {
  try {
    const replacementId = req.params.id;
    
    // Get current replacement
    const [current] = await pool.execute(
      `SELECT * FROM employee_replacements WHERE id = ?`,
      [replacementId]
    );
    
    if (current.length === 0) {
      return res.status(404).json({ error: "Replacement not found" });
    }
    
    const currentReplacement = current[0];
    
    // Get previous replacement (where newEmployeeId = current oldEmployeeId)
    const [previous] = await pool.execute(
      `SELECT er.*, e1.name AS oldEmployeeName, e2.name AS newEmployeeName
       FROM employee_replacements er
       JOIN employees e1 ON er.oldEmployeeId = e1.id
       JOIN employees e2 ON er.newEmployeeId = e2.id
       WHERE er.newEmployeeId = ?
       ORDER BY er.replacementDate DESC
       LIMIT 1`,
      [currentReplacement.oldEmployeeId]
    );
    
    // Get next replacement (where oldEmployeeId = current newEmployeeId)
    const [next] = await pool.execute(
      `SELECT er.*, e1.name AS oldEmployeeName, e2.name AS newEmployeeName
       FROM employee_replacements er
       JOIN employees e1 ON er.oldEmployeeId = e1.id
       JOIN employees e2 ON er.newEmployeeId = e2.id
       WHERE er.oldEmployeeId = ?
       ORDER BY er.replacementDate ASC
       LIMIT 1`,
      [currentReplacement.newEmployeeId]
    );
    
    res.json({
      previous: previous.length > 0 ? previous[0] : null,
      next: next.length > 0 ? next[0] : null
    });
  } catch (err) {
    console.error("❌ Adjacent Replacements Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});

// Enhanced Replace Employee with chain tracking
router.post("/:id/replace", async (req, res) => {
  const oldEmployeeId = req.params.id;
  const { 
    registerDate, name, fatherName, age, education,
    designation, department, salary, reference,
    idCardNumber, address, phoneNumber, reason,
    previousReplacementId  // New parameter for chain tracking
  } = req.body;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Create new employee
    const [insertResult] = await conn.execute(
      `INSERT INTO employees
      (registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber, isActive)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)`,
      [registerDate, name, fatherName, age, education, designation, department, salary, reference, idCardNumber, address, phoneNumber]
    );

    const newEmployeeId = insertResult.insertId;

    // 2. Deactivate old employee
    await conn.execute(
      "UPDATE employees SET isActive = 0 WHERE id = ?",
      [oldEmployeeId]
    );

    // 3. Track replacement with chain information
    await conn.execute(
      `INSERT INTO employee_replacements (oldEmployeeId, newEmployeeId, reason, replacementDate, previousReplacementId)
       VALUES (?, ?, ?, CURDATE(), ?)`,
      [oldEmployeeId, newEmployeeId, reason || null, previousReplacementId || null]
    );

    // 4. If there was a previous replacement, update its next_replacement_id
    if (previousReplacementId) {
      const replacementInsertId = await conn.execute('SELECT LAST_INSERT_ID() as id');
      const newReplacementId = replacementInsertId[0][0].id;
      
      await conn.execute(
        `UPDATE employee_replacements 
         SET nextReplacementId = ? 
         WHERE id = ?`,
        [newReplacementId, previousReplacementId]
      );
    }

    await conn.commit();

    res.status(201).json({
      message: "Employee replaced successfully",
      oldEmployeeId,
      newEmployeeId,
      previousReplacementId: previousReplacementId || null
    });
  } catch (err) {
    await conn.rollback();
    console.error("❌ Replace Employee Error:", err);
    res.status(500).json({ error: "Database error" });
  } finally {
    conn.release();
  }
});

// Get replacement details by ID
router.get("/replacements/:id", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT er.*, e1.name AS oldEmployeeName, e2.name AS newEmployeeName,
              er_prev.id AS prevId, er_next.id AS nextId
       FROM employee_replacements er
       JOIN employees e1 ON er.oldEmployeeId = e1.id
       JOIN employees e2 ON er.newEmployeeId = e2.id
       LEFT JOIN employee_replacements er_prev ON er.previousReplacementId = er_prev.id
       LEFT JOIN employee_replacements er_next ON er.nextReplacementId = er_next.id
       WHERE er.id = ?`,
      [req.params.id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: "Replacement not found" });
    }
    
    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Replacement Details Error:", err);
    res.status(500).json({ error: "Database error" });
  }
});


module.exports = router;
