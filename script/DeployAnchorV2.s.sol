// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AnchorV2} from "../src/AnchorV2.sol";

/**
 * Deploys AnchorV2 owned by the multisig, with the anchor-worker signer as its only submitter.
 * The deployer key pays for the deployment and gets no rights on the contract.
 *
 *   PRIVATE_KEY          deployer (funded on the target chain)
 *   ANCHOR_V2_OWNER      the multisig that administers the contract
 *   ANCHOR_V2_SUBMITTER  the anchor-worker signer (HORIZEN_MAINNET_PRIVATE_KEY's address)
 */
contract DeployAnchorV2 is Script {
    function run() external returns (AnchorV2 anchor) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("ANCHOR_V2_OWNER");
        address[] memory submitters = new address[](1);
        submitters[0] = vm.envAddress("ANCHOR_V2_SUBMITTER");

        vm.startBroadcast(deployerPrivateKey);
        anchor = new AnchorV2(owner, submitters);
        vm.stopBroadcast();

        console.log("AnchorV2 deployed to:", address(anchor));
        console.log("owner:", owner);
        console.log("submitter:", submitters[0]);
    }
}
