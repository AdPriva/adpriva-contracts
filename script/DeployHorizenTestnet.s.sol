// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

/**
 * @title DeployHorizenTestnet
 * @notice Deployment script for Horizen testnet (Caldera)
 * @dev Usage: forge script script/DeployHorizenTestnet.s.sol:DeployHorizenTestnet --rpc-url horizen_testnet --broadcast
 */
contract DeployHorizenTestnet is Script {
    function run() external returns (Anchor) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("================================================");
        console.log("Deploying Anchor Contract to Horizen Testnet");
        console.log("================================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);

        // Check deployer balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance);
        require(balance > 0, "Insufficient balance for deployment");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Anchor contract
        Anchor anchor = new Anchor();

        vm.stopBroadcast();

        console.log("================================================");
        console.log("Deployment Successful!");
        console.log("================================================");
        console.log("Anchor contract deployed to:", address(anchor));
        console.log("Explorer:", "https://horizen-testnet.explorer.caldera.xyz/");
        console.log("");
        console.log("Next steps:");
        console.log("1. Update ANCHOR_HORIZEN_TESTNET_ADDRESS in .env");
        console.log("2. Verify contract on Horizen testnet explorer");
        console.log("3. Test with backend integration");
        console.log("================================================");

        return anchor;
    }
}

