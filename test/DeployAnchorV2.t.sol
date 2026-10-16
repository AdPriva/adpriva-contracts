// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {AnchorV2} from "../src/AnchorV2.sol";
import {DeployAnchorV2} from "../script/DeployAnchorV2.s.sol";

contract DeployAnchorV2Test is Test {
    // anvil's first well-known dev key; never funded anywhere real.
    string internal constant DEV_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
    address internal constant MULTISIG = address(0x5AFE);
    address internal constant WORKER_SIGNER = address(0x5B);

    function test_Run_DeploysWithTheMultisigOwnerAndOnlyTheWorkerSigner() public {
        vm.setEnv("PRIVATE_KEY", DEV_KEY);
        vm.setEnv("ANCHOR_V2_OWNER", vm.toString(MULTISIG));
        vm.setEnv("ANCHOR_V2_SUBMITTER", vm.toString(WORKER_SIGNER));

        AnchorV2 anchor = new DeployAnchorV2().run();

        assertEq(anchor.owner(), MULTISIG);
        assertTrue(anchor.isSubmitter(WORKER_SIGNER));
        assertFalse(anchor.isSubmitter(vm.addr(vm.envUint("PRIVATE_KEY"))), "deployer gets no rights");
        assertFalse(anchor.paused());
    }
}
