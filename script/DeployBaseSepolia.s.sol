// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

/**
 * @title DeployBaseSepolia
 * @notice Deployment script for Base Sepolia testnet with verification
 * @dev Usage: forge script script/DeployBaseSepolia.s.sol:DeployBaseSepolia --rpc-url base_sepolia --broadcast --verify
 */
contract DeployBaseSepolia is Script {
    function run() external returns (Anchor) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("================================================");
        console.log("Deploying Anchor Contract to Base Sepolia Testnet");
        console.log("================================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);

        // Verify we're on Base Sepolia
        require(block.chainid == 84532, "Must deploy to Base Sepolia (chainId 84532)");

        // Check deployer balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance);
        require(balance > 0.001 ether, "Insufficient balance for deployment");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Anchor contract
        Anchor anchor = new Anchor();

        vm.stopBroadcast();

        console.log("================================================");
        console.log("Deployment Successful!");
        console.log("================================================");
        console.log("Anchor contract deployed to:", address(anchor));
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contract on Basescan Sepolia");
        console.log("2. Update ANCHOR_BASE_SEPOLIA_ADDRESS in .env");
        console.log("3. Run smoke tests on testnet");
        console.log("4. Test backend integration");
        console.log("================================================");

        return anchor;
    }
}

