const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");


const authRoutes = require("./routes/authRoutes");
const departmentRoutes = require("./routes/departmentRoutes");
const employeeRoutes = require("./routes/employeeRoutes");
const payrollRoutes = require('./routes/payrollRoutes');
const kharchaRoutes = require('./routes/kharchaRoutes');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/departments", departmentRoutes);
app.use("/api/employees", employeeRoutes);
app.use('/api/payroll', payrollRoutes);
app.use('/api/kharcha', kharchaRoutes);


const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
