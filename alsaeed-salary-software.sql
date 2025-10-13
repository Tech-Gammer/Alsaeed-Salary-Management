-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 13, 2025 at 06:56 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `alsaeed-salary-software`
--

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `total_salary` decimal(12,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `name`, `description`, `total_salary`) VALUES
(7, 'Accounts', NULL, 0.00),
(8, 'Fresh Cake', NULL, 0.00),
(9, 'Nimko', NULL, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `department_salary_history`
--

CREATE TABLE `department_salary_history` (
  `id` int(11) NOT NULL,
  `department_id` int(11) NOT NULL,
  `old_salary` decimal(12,2) DEFAULT NULL,
  `new_salary` decimal(12,2) DEFAULT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `id` int(11) NOT NULL,
  `registerDate` date NOT NULL,
  `name` varchar(255) NOT NULL,
  `fatherName` varchar(255) DEFAULT NULL,
  `age` int(11) DEFAULT NULL,
  `education` varchar(255) DEFAULT NULL,
  `designation` varchar(255) NOT NULL,
  `department` varchar(255) NOT NULL,
  `salary` decimal(10,2) NOT NULL,
  `reference` varchar(255) DEFAULT NULL,
  `idCardNumber` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `phoneNumber` varchar(20) NOT NULL,
  `isActive` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`id`, `registerDate`, `name`, `fatherName`, `age`, `education`, `designation`, `department`, `salary`, `reference`, `idCardNumber`, `address`, `phoneNumber`, `isActive`) VALUES
(9, '2025-10-13', 'Umair', 'Arshad', 25, 'BS CS', 'Software Developer', 'Accounts', 45000.00, '', '3410116240343', 'Alam Chowk', '03076455926', 1),
(10, '2025-10-13', 'Hassan', 'N/A', 31, 'BA', 'Computer Operator', 'Accounts', 35000.00, 'Self', '165131321513', 'Gap Chowk', '030413256484', 0),
(11, '2025-10-13', 'Ali Haider', 'Muhammad Ameen', 22, 'FA', 'Computer Operator', 'Accounts', 35000.00, 'Umair Arshad', '1561231843', 'Alam Chowk', '03007465064', 1),
(12, '2025-10-13', 'مستری رفیق', 'نل', 50, 'BSCS', 'Mistri Nimko', 'Nimko', 55000.00, '', '341051313532', 'Alam Chowk', '03076455926', 1),
(13, '2025-10-13', 'علی اکبر', '', 30, 'BsCS', 'Helper', 'Nimko', 29000.00, '', '341016426452', 'Gap Chowk', '03076445926', 1),
(14, '2025-10-13', 'علی', '', 25, 'Matric', 'Helper', 'Nimko', 17000.00, '', '13151435212', '', '03074645559', 1);

-- --------------------------------------------------------

--
-- Table structure for table `employee_expenses`
--

CREATE TABLE `employee_expenses` (
  `id` int(11) NOT NULL,
  `employeeId` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `expenseDate` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_expenses`
--

INSERT INTO `employee_expenses` (`id`, `employeeId`, `description`, `amount`, `expenseDate`) VALUES
(3, 9, 'Kharcha', 3000.00, '2025-10-23 00:00:00'),
(4, 9, 'kharcha', 1000.00, '2025-10-23 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `employee_loans`
--

CREATE TABLE `employee_loans` (
  `id` int(11) NOT NULL,
  `employeeId` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `loanDate` date NOT NULL,
  `description` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_loans`
--

INSERT INTO `employee_loans` (`id`, `employeeId`, `amount`, `loanDate`, `description`) VALUES
(2, 9, 150000.00, '2025-10-13', 'bike leni he');

-- --------------------------------------------------------

--
-- Table structure for table `employee_replacements`
--

CREATE TABLE `employee_replacements` (
  `id` int(11) NOT NULL,
  `oldEmployeeId` int(11) NOT NULL,
  `newEmployeeId` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `replacementDate` date NOT NULL,
  `previousReplacementId` int(11) DEFAULT NULL,
  `nextReplacementId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_replacements`
--

INSERT INTO `employee_replacements` (`id`, `oldEmployeeId`, `newEmployeeId`, `reason`, `replacementDate`, `previousReplacementId`, `nextReplacementId`) VALUES
(5, 10, 11, 'None', '2025-10-13', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `kharcha`
--

CREATE TABLE `kharcha` (
  `id` int(11) NOT NULL,
  `department_id` int(11) DEFAULT NULL,
  `period_id` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `kharcha_type` enum('department','individual') NOT NULL DEFAULT 'department',
  `employee_id` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `kharcha`
--

INSERT INTO `kharcha` (`id`, `department_id`, `period_id`, `description`, `amount`, `date`, `created_at`, `updated_at`, `kharcha_type`, `employee_id`) VALUES
(2, 9, 8, 'Kharcha', 30000.00, '2025-10-23', '2025-10-13 07:32:53', '2025-10-13 07:32:53', 'department', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `payroll_periods`
--

CREATE TABLE `payroll_periods` (
  `id` int(11) NOT NULL,
  `period_name` varchar(255) NOT NULL,
  `period_type` enum('monthly','weekly','custom','full_month','custom_range') DEFAULT 'full_month',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payroll_periods`
--

INSERT INTO `payroll_periods` (`id`, `period_name`, `period_type`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(8, 'Salary - October 2025', 'full_month', '2025-10-01', '2025-10-31', '2025-10-13 07:27:54', '2025-10-13 07:27:54');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `department_salary_history`
--
ALTER TABLE `department_salary_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_expenses`
--
ALTER TABLE `employee_expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employeeId` (`employeeId`);

--
-- Indexes for table `employee_loans`
--
ALTER TABLE `employee_loans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employeeId` (`employeeId`);

--
-- Indexes for table `employee_replacements`
--
ALTER TABLE `employee_replacements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `oldEmployeeId` (`oldEmployeeId`),
  ADD KEY `newEmployeeId` (`newEmployeeId`),
  ADD KEY `previousReplacementId` (`previousReplacementId`),
  ADD KEY `nextReplacementId` (`nextReplacementId`);

--
-- Indexes for table `kharcha`
--
ALTER TABLE `kharcha`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`),
  ADD KEY `period_id` (`period_id`);

--
-- Indexes for table `payroll_periods`
--
ALTER TABLE `payroll_periods`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `department_salary_history`
--
ALTER TABLE `department_salary_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `employee_expenses`
--
ALTER TABLE `employee_expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `employee_loans`
--
ALTER TABLE `employee_loans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `employee_replacements`
--
ALTER TABLE `employee_replacements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `kharcha`
--
ALTER TABLE `kharcha`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payroll_periods`
--
ALTER TABLE `payroll_periods`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `department_salary_history`
--
ALTER TABLE `department_salary_history`
  ADD CONSTRAINT `department_salary_history_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_expenses`
--
ALTER TABLE `employee_expenses`
  ADD CONSTRAINT `employee_expenses_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_loans`
--
ALTER TABLE `employee_loans`
  ADD CONSTRAINT `employee_loans_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_replacements`
--
ALTER TABLE `employee_replacements`
  ADD CONSTRAINT `employee_replacements_ibfk_1` FOREIGN KEY (`oldEmployeeId`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `employee_replacements_ibfk_2` FOREIGN KEY (`newEmployeeId`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `employee_replacements_ibfk_3` FOREIGN KEY (`previousReplacementId`) REFERENCES `employee_replacements` (`id`),
  ADD CONSTRAINT `employee_replacements_ibfk_4` FOREIGN KEY (`nextReplacementId`) REFERENCES `employee_replacements` (`id`);

--
-- Constraints for table `kharcha`
--
ALTER TABLE `kharcha`
  ADD CONSTRAINT `kharcha_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kharcha_ibfk_2` FOREIGN KEY (`period_id`) REFERENCES `payroll_periods` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
