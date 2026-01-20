// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

contract DeployScript is Script {
    Anchor public anchor;

    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        anchor = new Anchor();
        console.log("Anchor deployed to:", address(anchor));

        vm.stopBroadcast();

        return address(anchor);
    }
}

