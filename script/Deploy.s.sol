// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

contract DeployAnchor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Anchor anchor = new Anchor();
        console.log("Anchor deployed to:", address(anchor));

        vm.stopBroadcast();
    }
}
