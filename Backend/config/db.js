const mysql = require("mysql2/promise");

const pool = mysql.createPool({
  host: "localhost",   // change if needed
  user: "root",        // your MySQL username
  password: "",        // your MySQL password
  database: "alsaeed-salary-software",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;
