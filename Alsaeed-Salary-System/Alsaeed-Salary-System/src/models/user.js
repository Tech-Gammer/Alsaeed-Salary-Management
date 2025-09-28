const { DataTypes } = require("sequelize");
const sequelize = require("../db/connection");

const User = sequelize.define("User", {
  username: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
});

// Method to find a user by username
User.findByUsername = async function (username) {
  return await this.findOne({ where: { username } });
};

// Method to find a user by email
User.findByEmail = async function (email) {
  return await this.findOne({ where: { email } });
};

module.exports = User;