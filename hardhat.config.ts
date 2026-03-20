import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

import * as dotenv from "dotenv";
dotenv.config();

// // 2. Resgata as variáveis. Se não encontrar, usa uma string vazia para não quebrar o código de cara.
// const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
// const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";

const AMOY_RPC_URL = process.env.AMOY_RPC_URL || "https://rpc-amoy.polygon.technology";
const AMOY_PRIVATE_KEY = process.env.AMOY_PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";
const AMOY_PRIVATE_KEY_2 = process.env.AMOY_PRIVATE_KEY_2 || "0x0000000000000000000000000000000000000000000000000000000000000000";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // sepolia: {
    //   url: SEPOLIA_RPC_URL,
    //   accounts: [SEPOLIA_PRIVATE_KEY],
    // },
    polygonAmoy: {
      url: AMOY_RPC_URL,
      accounts: [AMOY_PRIVATE_KEY, AMOY_PRIVATE_KEY_2],
    },
  },
};

export default config;