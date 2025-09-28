# Alsaeed Salary System

## Overview
The Alsaeed Salary System is a Node.js application designed to manage user authentication and salary-related functionalities. It utilizes an SQL database for data storage and retrieval.

## Features
- User registration and login
- Secure password storage using hashing
- JWT-based authentication for protected routes

## Project Structure
```
Alsaeed-Salary-System
├── src
│   ├── index.js               # Entry point of the application
│   ├── db
│   │   └── connection.js      # Database connection setup
│   ├── models
│   │   └── user.js            # User model definition
│   ├── controllers
│   │   └── authController.js   # Authentication logic
│   ├── routes
│   │   └── authRoutes.js      # Authentication routes
│   └── utils
│       └── helpers.js         # Utility functions
├── package.json                # Project metadata and dependencies
├── .env                        # Environment variables
└── README.md                   # Project documentation
```

## Installation
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd Alsaeed-Salary-System
   ```
3. Install the dependencies:
   ```
   npm install
   ```

## Configuration
1. Create a `.env` file in the root directory and add your database connection details and secret keys:
   ```
   DATABASE_URL=your_database_url
   SECRET_KEY=your_secret_key
   ```

## Usage
1. Start the server:
   ```
   npm start
   ```
2. The server will run on `http://localhost:3000`.

## API Endpoints
- **POST /register**: Register a new user
- **POST /login**: Log in an existing user
- **GET /profile**: Access protected user profile (requires authentication)

## License
This project is licensed under the MIT License.