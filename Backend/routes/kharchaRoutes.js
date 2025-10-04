const express = require("express");
const router = express.Router();
const pool = require("../config/db");

// ✅ Get all kharchas with filtering (updated for period_id)
router.get("/", async (req, res) => {
  try {
    const { department_id, employee_id, period_id, kharcha_type, page = 1, limit = 50 } = req.query;
    
    let query = `
      SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,
        d.name as department_name,
        e.name as employee_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
      FROM kharcha k
      LEFT JOIN departments d ON k.department_id = d.id
      LEFT JOIN employees e ON k.employee_id = e.id
      JOIN payroll_periods p ON k.period_id = p.id
      WHERE 1=1
    `;
    const params = [];

    // Apply filters
    if (department_id) {
      query += " AND k.department_id = ?";
      params.push(department_id);
    }

    if (employee_id) {
      query += " AND k.employee_id = ?";
      params.push(employee_id);
    }

    if (period_id) {
      query += " AND k.period_id = ?";
      params.push(period_id);
    }

    if (kharcha_type) {
      query += " AND k.kharcha_type = ?";
      params.push(kharcha_type);
    }

    // Add ordering and pagination
    query += " ORDER BY k.date DESC, k.created_at DESC";
    
    const offset = (page - 1) * limit;
    query += " LIMIT ? OFFSET ?";
    params.push(parseInt(limit), offset);

    const [rows] = await pool.query(query, params);
    
    // Get total count for pagination
    let countQuery = `
      SELECT COUNT(*) as total 
      FROM kharcha k 
      WHERE 1=1
    `;
    const countParams = [];

    if (department_id) {
      countQuery += " AND k.department_id = ?";
      countParams.push(department_id);
    }

    if (employee_id) {
      countQuery += " AND k.employee_id = ?";
      countParams.push(employee_id);
    }

    if (period_id) {
      countQuery += " AND k.period_id = ?";
      countParams.push(period_id);
    }

    if (kharcha_type) {
      countQuery += " AND k.kharcha_type = ?";
      countParams.push(kharcha_type);
    }

    const [countRows] = await pool.query(countQuery, countParams);
    const total = countRows[0].total;

    res.json({
      kharchas: rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    console.error("❌ Get Kharchas Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get kharcha by ID (updated for period_id)
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query(
      `SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,  -- ✅ Format date properly
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,  -- ✅ Format created_at
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,  -- ✅ Format updated_at
        d.name as department_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,  -- ✅ Format period dates
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
       FROM kharcha k
       JOIN departments d ON k.department_id = d.id
       JOIN payroll_periods p ON k.period_id = p.id
       WHERE k.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Kharcha record not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Get Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// // ✅ Add new kharcha (updated for period_id)
// router.post("/", async (req, res) => {
//   const { department_id, employee_id, amount, date, period_id, description, kharcha_type } = req.body;

//   // Validation
//   if (!kharcha_type || !['department', 'individual'].includes(kharcha_type)) {
//     return res.status(400).json({ error: "Valid kharcha_type (department/individual) is required" });
//   }

//   if (kharcha_type === 'department' && !department_id) {
//     return res.status(400).json({ error: "Department ID is required for department kharcha" });
//   }

//   if (kharcha_type === 'individual' && !employee_id) {
//     return res.status(400).json({ error: "Employee ID is required for individual kharcha" });
//   }

//   if (!period_id) {
//     return res.status(400).json({ error: "Period ID is required" });
//   }

//   if (!amount || amount <= 0) {
//     return res.status(400).json({ error: "Valid amount is required" });
//   }

//   if (!date) {
//     return res.status(400).json({ error: "Date is required" });
//   }

//   try {
//     // Check if period exists
//     const [periodRows] = await pool.query("SELECT id FROM payroll_periods WHERE id = ?", [period_id]);
//     if (periodRows.length === 0) {
//       return res.status(404).json({ error: "Payroll period not found" });
//     }

//     // Check based on kharcha type
//     if (kharcha_type === 'department') {
//       // Check if department exists
//       const [deptRows] = await pool.query("SELECT id FROM departments WHERE id = ?", [department_id]);
//       if (deptRows.length === 0) {
//         return res.status(404).json({ error: "Department not found" });
//       }

//       // Check for duplicate department kharcha
//       const [existingRows] = await pool.query(
//         "SELECT id FROM kharcha WHERE department_id = ? AND period_id = ? AND employee_id IS NULL",
//         [department_id, period_id]
//       );

//       if (existingRows.length > 0) {
//         return res.status(409).json({ 
//           error: "Kharcha already exists for this department in the selected period",
//           existing_id: existingRows[0].id
//         });
//       }
//     } else {
//       // Individual kharcha
//       // Check if employee exists
//       const [empRows] = await pool.query("SELECT id, name FROM employees WHERE id = ?", [employee_id]);
//       if (empRows.length === 0) {
//         return res.status(404).json({ error: "Employee not found" });
//       }

//       // Check for duplicate individual kharcha
//       const [existingRows] = await pool.query(
//         "SELECT id FROM kharcha WHERE employee_id = ? AND period_id = ?",
//         [employee_id, period_id]
//       );

//       if (existingRows.length > 0) {
//         return res.status(409).json({ 
//           error: "Kharcha already exists for this employee in the selected period",
//           existing_id: existingRows[0].id
//         });
//       }
//     }

//     // Insert new kharcha
//     const [result] = await pool.query(
//       "INSERT INTO kharcha (department_id, employee_id, amount, date, period_id, description, kharcha_type) VALUES (?, ?, ?, ?, ?, ?, ?)",
//       [department_id || null, employee_id || null, amount, date, period_id, description || null, kharcha_type]
//     );

//     // Get the created record with joins
//     const [newRecord] = await pool.query(
//       `SELECT 
//         k.*,
//         DATE_FORMAT(k.date, '%Y-%m-%d') as date,
//         DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,
//         DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,
//         d.name as department_name,
//         e.name as employee_name,
//         p.period_name,
//         DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,
//         DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
//         p.period_type
//        FROM kharcha k
//        LEFT JOIN departments d ON k.department_id = d.id
//        LEFT JOIN employees e ON k.employee_id = e.id
//        JOIN payroll_periods p ON k.period_id = p.id
//        WHERE k.id = ?`,
//       [result.insertId]
//     );

//     res.status(201).json({
//       message: "Kharcha added successfully",
//       kharcha: newRecord[0]
//     });
//   } catch (err) {
//     console.error("❌ Add Kharcha Error:", err);
//     res.status(500).json({ error: "Database error", details: err.message });
//   }
// });
// ✅ Add new kharcha (updated for period_id) - ALLOW MULTIPLE
router.post("/", async (req, res) => {
  const { department_id, employee_id, amount, date, period_id, description, kharcha_type } = req.body;

  // Validation
  if (!kharcha_type || !['department', 'individual'].includes(kharcha_type)) {
    return res.status(400).json({ error: "Valid kharcha_type (department/individual) is required" });
  }

  if (kharcha_type === 'department' && !department_id) {
    return res.status(400).json({ error: "Department ID is required for department kharcha" });
  }

  if (kharcha_type === 'individual' && !employee_id) {
    return res.status(400).json({ error: "Employee ID is required for individual kharcha" });
  }

  if (!period_id) {
    return res.status(400).json({ error: "Period ID is required" });
  }

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: "Valid amount is required" });
  }

  if (!date) {
    return res.status(400).json({ error: "Date is required" });
  }

  try {
    // Check if period exists
    const [periodRows] = await pool.query("SELECT id FROM payroll_periods WHERE id = ?", [period_id]);
    if (periodRows.length === 0) {
      return res.status(404).json({ error: "Payroll period not found" });
    }

    // Check based on kharcha type
    if (kharcha_type === 'department') {
      // Check if department exists
      const [deptRows] = await pool.query("SELECT id FROM departments WHERE id = ?", [department_id]);
      if (deptRows.length === 0) {
        return res.status(404).json({ error: "Department not found" });
      }
    } else {
      // Individual kharcha - Check if employee exists
      const [empRows] = await pool.query("SELECT id, name FROM employees WHERE id = ?", [employee_id]);
      if (empRows.length === 0) {
        return res.status(404).json({ error: "Employee not found" });
      }
    }

    // Insert new kharcha (NO DUPLICATE CHECK - ALLOW MULTIPLE)
    const [result] = await pool.query(
      "INSERT INTO kharcha (department_id, employee_id, amount, date, period_id, description, kharcha_type) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [department_id || null, employee_id || null, amount, date, period_id, description || null, kharcha_type]
    );

    // Get the created record with joins
    const [newRecord] = await pool.query(
      `SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,
        d.name as department_name,
        e.name as employee_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
       FROM kharcha k
       LEFT JOIN departments d ON k.department_id = d.id
       LEFT JOIN employees e ON k.employee_id = e.id
       JOIN payroll_periods p ON k.period_id = p.id
       WHERE k.id = ?`,
      [result.insertId]
    );

    res.status(201).json({
      message: "Kharcha added successfully",
      kharcha: newRecord[0]
    });
  } catch (err) {
    console.error("❌ Add Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Update kharcha (updated for period_id)
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { department_id, amount, date, period_id, description } = req.body;

  try {
    // Check if kharcha exists
    const [existingRows] = await pool.query("SELECT * FROM kharcha WHERE id = ?", [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ error: "Kharcha record not found" });
    }

    // Check for duplicate kharcha (excluding current record)
    if (department_id && period_id) {
      const [duplicateRows] = await pool.query(
        "SELECT id FROM kharcha WHERE department_id = ? AND period_id = ? AND id != ?",
        [department_id, period_id, id]
      );

      if (duplicateRows.length > 0) {
        return res.status(409).json({ 
          error: "Kharcha already exists for this department in the selected period"
        });
      }
    }

    // Build dynamic update query
    const updateFields = [];
    const updateParams = [];

    if (department_id !== undefined) {
      updateFields.push("department_id = ?");
      updateParams.push(department_id);
    }

    if (amount !== undefined) {
      updateFields.push("amount = ?");
      updateParams.push(amount);
    }

    if (date !== undefined) {
      updateFields.push("date = ?");
      updateParams.push(date);
    }

    if (period_id !== undefined) {
      updateFields.push("period_id = ?");
      updateParams.push(period_id);
    }

    if (description !== undefined) {
      updateFields.push("description = ?");
      updateParams.push(description);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    updateParams.push(id);

    const query = `UPDATE kharcha SET ${updateFields.join(", ")} WHERE id = ?`;
    await pool.query(query, updateParams);

    // Get updated record
    const [updatedRows] = await pool.query(
      `SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,  -- ✅ Format date properly
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,  -- ✅ Format created_at
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,  -- ✅ Format updated_at
        d.name as department_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,  -- ✅ Format period dates
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
       FROM kharcha k
       JOIN departments d ON k.department_id = d.id
       JOIN payroll_periods p ON k.period_id = p.id
       WHERE k.id = ?`,
      [id]
    );

    res.json({
      message: "Kharcha updated successfully",
      kharcha: updatedRows[0]
    });
  } catch (err) {
    console.error("❌ Update Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Delete kharcha (unchanged)
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Check if kharcha exists
    const [rows] = await pool.query("SELECT * FROM kharcha WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: "Kharcha record not found" });
    }

    await pool.query("DELETE FROM kharcha WHERE id = ?", [id]);

    res.json({ 
      message: "Kharcha deleted successfully",
      deleted_id: id
    });
  } catch (err) {
    console.error("❌ Delete Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get kharcha statistics (updated for period_id)
router.get("/stats/summary", async (req, res) => {
  try {
    const { period_id, department_id } = req.query;

    let query = `
      SELECT 
        COUNT(*) as total_records,
        SUM(amount) as total_amount,
        AVG(amount) as average_amount,
        MIN(amount) as min_amount,
        MAX(amount) as max_amount,
        COUNT(DISTINCT department_id) as department_count
      FROM kharcha
      WHERE 1=1
    `;
    const params = [];

    if (period_id) {
      query += " AND period_id = ?";
      params.push(period_id);
    }

    if (department_id) {
      query += " AND department_id = ?";
      params.push(department_id);
    }

    const [stats] = await pool.query(query, params);

    res.json(stats[0]);
  } catch (err) {
    console.error("❌ Kharcha Stats Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get kharcha by department (updated for period_id)
router.get("/department/:department_id", async (req, res) => {
  try {
    const { department_id } = req.params;
    const { period_id, year, page = 1, limit = 50 } = req.query;

    let query = `
      SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,  -- ✅ Format date properly
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,  -- ✅ Format created_at
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,  -- ✅ Format updated_at
        d.name as department_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,  -- ✅ Format period dates
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
      FROM kharcha k
      JOIN departments d ON k.department_id = d.id
      JOIN payroll_periods p ON k.period_id = p.id
      WHERE k.department_id = ?
    `;
    const params = [department_id];

    if (period_id) {
      query += " AND k.period_id = ?";
      params.push(period_id);
    }

    if (year) {
      query += " AND YEAR(p.start_date) = ?";
      params.push(year);
    }

    query += " ORDER BY p.start_date DESC, k.date DESC";
    
    const offset = (page - 1) * limit;
    query += " LIMIT ? OFFSET ?";
    params.push(parseInt(limit), offset);

    const [rows] = await pool.query(query, params);

    // Get total count
    let countQuery = `
      SELECT COUNT(*) as total 
      FROM kharcha k
      JOIN payroll_periods p ON k.period_id = p.id
      WHERE k.department_id = ?
    `;
    const countParams = [department_id];

    if (period_id) {
      countQuery += " AND k.period_id = ?";
      countParams.push(period_id);
    }

    if (year) {
      countQuery += " AND YEAR(p.start_date) = ?";
      countParams.push(year);
    }

    const [countRows] = await pool.query(countQuery, countParams);
    const total = countRows[0].total;

    res.json({
      kharchas: rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    console.error("❌ Department Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get kharcha by period (updated for period_id)
router.get("/period/:period_id", async (req, res) => {
  try {
    const { period_id } = req.params;
    const { page = 1, limit = 50 } = req.query;

    const [rows] = await pool.query(
      `SELECT 
        k.*,
        DATE_FORMAT(k.date, '%Y-%m-%d') as date,  -- ✅ Format date properly
        DATE_FORMAT(k.created_at, '%Y-%m-%d %H:%i:%s') as created_at,  -- ✅ Format created_at
        DATE_FORMAT(k.updated_at, '%Y-%m-%d %H:%i:%s') as updated_at,  -- ✅ Format updated_at
        d.name as department_name,
        p.period_name,
        DATE_FORMAT(p.start_date, '%Y-%m-%d') as period_start_date,  -- ✅ Format period dates
        DATE_FORMAT(p.end_date, '%Y-%m-%d') as period_end_date,
        p.period_type
       FROM kharcha k
       JOIN departments d ON k.department_id = d.id
       JOIN payroll_periods p ON k.period_id = p.id
       WHERE k.period_id = ?
       ORDER BY k.amount DESC, d.name ASC
       LIMIT ? OFFSET ?`,
      [period_id, parseInt(limit), (page - 1) * limit]
    );

    // Get total count
    const [countRows] = await pool.query(
      "SELECT COUNT(*) as total FROM kharcha WHERE period_id = ?",
      [period_id]
    );

    const total = countRows[0].total;

    res.json({
      kharchas: rows,
      period_id,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    console.error("❌ Period Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get available periods (now uses payroll_periods table)
router.get("/meta/periods", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
        p.id,
        p.period_name,
        p.start_date,
        p.end_date,
        p.period_type,
        COUNT(k.id) as kharcha_count,
        COALESCE(SUM(k.amount), 0) as total_kharcha
       FROM payroll_periods p
       LEFT JOIN kharcha k ON p.id = k.period_id
       GROUP BY p.id, p.period_name, p.start_date, p.end_date, p.period_type
       ORDER BY p.start_date DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Get Periods Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get department kharcha summary (updated for period_id)
router.get("/stats/department-summary", async (req, res) => {
  try {
    const { period_id } = req.query;

    let query = `
      SELECT 
        d.id,
        d.name as department_name,
        COALESCE(SUM(k.amount), 0) as total_kharcha,
        COALESCE(COUNT(k.id), 0) as kharcha_count,
        d.total_salary
      FROM departments d
      LEFT JOIN kharcha k ON d.id = k.department_id
      WHERE 1=1
    `;

    const params = [];

    if (period_id) {
      query += " AND k.period_id = ?";
      params.push(period_id);
    }

    query += " GROUP BY d.id, d.name, d.total_salary ORDER BY total_kharcha DESC";

    const [rows] = await pool.query(query, params);

    res.json(rows);
  } catch (err) {
    console.error("❌ Department Summary Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Bulk insert kharchas (updated for period_id)
router.post("/bulk", async (req, res) => {
  const { kharchas } = req.body;

  if (!Array.isArray(kharchas) || kharchas.length === 0) {
    return res.status(400).json({ error: "Kharchas array is required" });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const results = [];
    const errors = [];

    for (const kharcha of kharchas) {
      const { department_id, amount, date, period_id, description } = kharcha;

      // Validation
      if (!department_id || !amount || !date || !period_id) {
        errors.push({ kharcha, error: "Missing required fields" });
        continue;
      }

      try {
        // Check for duplicates
        const [existing] = await conn.query(
          "SELECT id FROM kharcha WHERE department_id = ? AND period_id = ?",
          [department_id, period_id]
        );

        if (existing.length > 0) {
          errors.push({ 
            kharcha, 
            error: "Duplicate kharcha for department and period",
            existing_id: existing[0].id
          });
          continue;
        }

        // Insert kharcha
        const [result] = await conn.query(
          "INSERT INTO kharcha (department_id, amount, date, period_id, description) VALUES (?, ?, ?, ?, ?)",
          [department_id, amount, date, period_id, description || null]
        );

        results.push({
          id: result.insertId,
          ...kharcha
        });
      } catch (err) {
        errors.push({ kharcha, error: err.message });
      }
    }

    await conn.commit();

    res.status(201).json({
      message: "Bulk kharcha operation completed",
      successful: results,
      failed: errors,
      summary: {
        total: kharchas.length,
        successful: results.length,
        failed: errors.length
      }
    });
  } catch (err) {
    await conn.rollback();
    console.error("❌ Bulk Kharcha Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  } finally {
    conn.release();
  }
});

// ✅ Get kharcha summary by period (new endpoint)
router.get("/stats/period-summary", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
        p.id,
        p.period_name,
        p.start_date,
        p.end_date,
        p.period_type,
        COUNT(k.id) as kharcha_count,
        COALESCE(SUM(k.amount), 0) as total_amount,
        COUNT(DISTINCT k.department_id) as department_count
       FROM payroll_periods p
       LEFT JOIN kharcha k ON p.id = k.period_id
       GROUP BY p.id, p.period_name, p.start_date, p.end_date, p.period_type
       ORDER BY p.start_date DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Period Summary Error:", err);
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

module.exports = router;