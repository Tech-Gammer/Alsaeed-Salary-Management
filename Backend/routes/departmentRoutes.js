const express = require("express");
const router = express.Router();
const pool = require("../config/db");

// ✅ Get all departments
router.get("/", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM departments");
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Add new department (with salary)
router.post("/", async (req, res) => {
  const { name, description, total_salary } = req.body;

  if (!name) return res.status(400).json({ error: "Department name is required" });

  try {
    const [result] = await pool.query(
      "INSERT INTO departments (name, description, total_salary) VALUES (?, ?, ?)",
      [name, description || null, total_salary || 0]
    );

    res.status(201).json({ id: result.insertId, name, description, total_salary: total_salary || 0 });
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err.message });
  }
});


// ✅ Update department (salary optional, history tracked if changed)
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { name, description, total_salary } = req.body;

  try {
    // Get current department info
    const [rows] = await pool.query("SELECT * FROM departments WHERE id = ?", [id]);
    if (rows.length === 0) return res.status(404).json({ error: "Department not found" });

    const currentDept = rows[0];
    const oldSalary = currentDept.total_salary;

    // Decide new salary → if not provided, keep old
    const newSalary = (total_salary !== undefined && total_salary !== null) ? total_salary : oldSalary;

    // Update department
    await pool.query(
      "UPDATE departments SET name = ?, description = ?, total_salary = ? WHERE id = ?",
      [name || currentDept.name, description || currentDept.description, newSalary, id]
    );

    // Log salary history only if changed
    if (oldSalary !== newSalary) {
      await pool.query(
        "INSERT INTO department_salary_history (department_id, old_salary, new_salary) VALUES (?, ?, ?)",
        [id, oldSalary, newSalary]
      );
    }

    res.json({ message: "Department updated successfully" });
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err.message });
  }
});


// ✅ Delete department
router.delete("/:id", async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query("DELETE FROM departments WHERE id = ?", [id]);
    res.json({ message: "Department deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err.message });
  }
});

// ✅ Get department salary history
router.get("/:id/salary-history", async (req, res) => {
  const { id } = req.params;

  try {
    const [rows] = await pool.query(
      "SELECT * FROM department_salary_history WHERE department_id = ? ORDER BY changed_at DESC",
      [id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err.message });
  }
});


module.exports = router;
