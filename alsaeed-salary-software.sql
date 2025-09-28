-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 28, 2025 at 01:35 PM
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
(5, 'Khamira', NULL, 1300000.00),
(6, 'Accounts', NULL, 0.00);

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

--
-- Dumping data for table `department_salary_history`
--

INSERT INTO `department_salary_history` (`id`, `department_id`, `old_salary`, `new_salary`, `changed_at`) VALUES
(2, 5, 600000.00, 1300000.00, '2025-09-28 10:40:47');

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
(6, '2025-09-27', 'Umair', 'Arshad', 25, 'BS COMPUTER SCIENCE', 'Helper', 'Accounts', 150000.00, 'ads', '3410116240343', 'Alam CHowk', '03046455926', 0),
(7, '2025-09-27', 'Hassan', 'Don\'t Know', 30, 'Don\'t Know', 'Don\'t Know', 'Accounts', 4500.00, 'Don\'t Know', 'Don\'t Know', 'Don\'t Know', '0316546852', 0),
(8, '2025-09-27', 'Umer', 'Don\'t Know', 12, 'Don\'t Know', 'Don\'t Know', 'Accounts', 0.00, 'Don\'t Know', 'Don\'t Know', 'Don\'t Know', 'Don\'t Know', 1);

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
(3, 6, 7, 'Don\'t Know', '2025-09-27', NULL, NULL),
(4, 7, 8, 'Don\'t Know', '2025-09-27', NULL, NULL);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `department_salary_history`
--
ALTER TABLE `department_salary_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `employee_expenses`
--
ALTER TABLE `employee_expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `employee_loans`
--
ALTER TABLE `employee_loans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `employee_replacements`
--
ALTER TABLE `employee_replacements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
