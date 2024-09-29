require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",

  // Sepolia network configuration
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Use your private key from .env file
      chainId: 11155111, // Sepolia Chain ID
      gas: "auto", // Allow automatic gas estimation
    },
  },
};
