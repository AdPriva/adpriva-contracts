// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

/**
 * @title DeployBase
 * @notice Deployment script for Base mainnet with verification
 * @dev Usage: forge script script/DeployBase.s.sol:DeployBase --rpc-url base_mainnet --broadcast --verify
 */
contract DeployBase is Script {
    function run() external returns (Anchor) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("================================================");
        console.log("Deploying Anchor Contract to Base Mainnet");
        console.log("================================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);

        // Verify we're on Base mainnet
        require(block.chainid == 8453, "Must deploy to Base mainnet (chainId 8453)");

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
        console.log("Transaction hash:", vm.toString(bytes32(0))); // Will be shown in broadcast logs
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contract on Basescan (should auto-verify if --verify flag used)");
        console.log("2. Update ANCHOR_BASE_MAINNET_ADDRESS in .env");
        console.log("3. Test with a single anchor transaction");
        console.log("4. Set up monitoring in OpenZeppelin Defender");
        console.log("5. Update backend configuration with new address");
        console.log("================================================");

        return anchor;
    }
}

