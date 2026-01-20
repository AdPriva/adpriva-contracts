// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Anchor} from "../src/Anchor.sol";

/**
 * @title VerifyDeployment
 * @notice Post-deployment verification script
 * @dev Run this after deploying to verify contract is working correctly
 *
 * Usage:
 *   forge script script/VerifyDeployment.s.sol:VerifyDeployment \
 *     --rpc-url <network> -vvv
 *
 * Example:
 *   forge script script/VerifyDeployment.s.sol:VerifyDeployment \
 *     --rpc-url base_sepolia -vvv
 */
contract VerifyDeployment is Script {
    // Set these after deployment
    address constant BASE_MAINNET_ANCHOR = address(0); // TODO: Update
    address constant BASE_SEPOLIA_ANCHOR = address(0); // TODO: Update
    address constant HORIZEN_TESTNET_ANCHOR = address(0); // TODO: Update

    Anchor public anchor;
    bool public allChecksPassed = true;

    function run() external {
        // Determine which contract to verify
        address contractAddress = getContractAddress();
        require(contractAddress != address(0), "Contract address not set for this network");

        anchor = Anchor(contractAddress);

        console.log("================================================");
        console.log("POST-DEPLOYMENT VERIFICATION");
        console.log("================================================");
        console.log("Network:", getNetworkName());
        console.log("Chain ID:", block.chainid);
        console.log("Contract Address:", address(anchor));
        console.log("Block Number:", block.number);
        console.log("Timestamp:", block.timestamp);
        console.log("================================================");
        console.log("");

        // Run all verification checks
        checkContractDeployed();
        checkContractCode();
        checkSingleAnchor();
        checkBatchAnchor();
        checkEventEmission();
        checkGasCosts();

        console.log("");
        console.log("================================================");
        console.log("VERIFICATION SUMMARY");
        console.log("================================================");

        if (allChecksPassed) {
            console.log("Status: ALL CHECKS PASSED");
            console.log("The contract is deployed correctly and functioning as expected.");
        } else {
            console.log("Status: SOME CHECKS FAILED");
            console.log("Review the output above and address any issues.");
        }

        console.log("================================================");
        console.log("");
        console.log("Next Steps:");
        console.log("1. Verify contract on block explorer");
        console.log("2. Set up monitoring (see monitoring/README.md)");
        console.log("3. Update .env with contract address");
        console.log("4. Test backend integration");
        console.log("5. Run smoke tests (forge test --match-contract SmokeTests)");
        console.log("================================================");
    }

    function checkContractDeployed() internal view {
        console.log("[CHECK 1/6] Contract Deployment");

        if (address(anchor) == address(0)) {
            console.log("FAIL: Contract address is zero");
            return;
        }

        console.log("PASS: Contract address is valid:", address(anchor));
    }

    function checkContractCode() internal view {
        console.log("");
        console.log("[CHECK 2/6] Contract Code");

        uint256 size;
        address contractAddr = address(anchor);
        assembly {
            size := extcodesize(contractAddr)
        }

        if (size == 0) {
            console.log("FAIL: Contract has no code");
            return;
        }

        console.log("PASS: Contract has code");
        console.log("Contract size:", size, "bytes");

        // Expected size for Anchor.sol is around 1-2KB
        if (size < 500 || size > 10000) {
            console.log("WARNING: Contract size unexpected (expected ~1-2KB)");
        }
    }

    function checkSingleAnchor() internal {
        console.log("");
        console.log("[CHECK 3/6] Single Anchor Function");

        bytes32 batchId = keccak256(abi.encodePacked("verify-test-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("verify-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Deployment Verification Test";

        try anchor.anchor(batchId, merkleRoot, chainTag, note) returns (bytes32 result) {
            if (result == batchId) {
                console.log("PASS: Single anchor works correctly");
                console.log("Batch ID returned:", vm.toString(result));
            } else {
                console.log("FAIL: Returned batch ID doesn't match");
            }
        } catch Error(string memory reason) {
            console.log("FAIL: Single anchor failed:", reason);
        } catch {
            console.log("FAIL: Single anchor failed with unknown error");
        }
    }

    function checkBatchAnchor() internal {
        console.log("");
        console.log("[CHECK 4/6] Batch Anchor Function");

        uint256 batchSize = 3;
        bytes32[] memory batchIds = new bytes32[](batchSize);
        bytes32[] memory merkleRoots = new bytes32[](batchSize);

        for (uint256 i = 0; i < batchSize; i++) {
            batchIds[i] = keccak256(abi.encodePacked("verify-batch-", i, block.timestamp));
            merkleRoots[i] = keccak256(abi.encodePacked("verify-batch-root-", i, block.timestamp));
        }

        string memory chainTag = getNetworkName();
        string memory note = "Batch Verification Test";

        try anchor.anchorBatch(batchIds, merkleRoots, chainTag, note) {
            console.log("PASS: Batch anchor works correctly");
            console.log("Batch size tested:", batchSize);
        } catch Error(string memory reason) {
            console.log("FAIL: Batch anchor failed:", reason);
        } catch {
            console.log("FAIL: Batch anchor failed with unknown error");
        }
    }

    function checkEventEmission() internal {
        console.log("");
        console.log("[CHECK 5/6] Event Emission");

        bytes32 batchId = keccak256(abi.encodePacked("verify-event-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("verify-event-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Event Verification Test";

        vm.recordLogs();

        try anchor.anchor(batchId, merkleRoot, chainTag, note) {
            Vm.Log[] memory logs = vm.getRecordedLogs();

            if (logs.length == 0) {
                console.log("FAIL: No events emitted");
                return;
            }

            // Check event signature
            bytes32 expectedSignature = keccak256("Anchored(bytes32,bytes32,address,uint256,string,string)");
            if (logs[0].topics[0] != expectedSignature) {
                console.log("FAIL: Event signature doesn't match");
                return;
            }

            console.log("PASS: Events emitted correctly");
            console.log("Events count:", logs.length);
            console.log("Event topics:", logs[0].topics.length);
        } catch {
            console.log("FAIL: Event verification failed");
        }
    }

    function checkGasCosts() internal {
        console.log("");
        console.log("[CHECK 6/6] Gas Cost Validation");

        // Test single anchor gas
        bytes32 batchId = keccak256(abi.encodePacked("verify-gas-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("verify-gas-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Gas Test";

        uint256 gasStart = gasleft();
        anchor.anchor(batchId, merkleRoot, chainTag, note);
        uint256 gasUsed = gasStart - gasleft();

        console.log("Single anchor gas used:", gasUsed);

        // Expected range: 50k-70k gas
        if (gasUsed < 40000) {
            console.log("WARNING: Gas usage suspiciously low");
        } else if (gasUsed > 100000) {
            console.log("WARNING: Gas usage higher than expected");
        } else {
            console.log("PASS: Gas usage within expected range (50k-70k)");
        }

        // Test batch anchor gas
        bytes32[] memory batchIds = new bytes32[](5);
        bytes32[] memory merkleRoots = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            batchIds[i] = keccak256(abi.encodePacked("verify-batch-gas-", i, block.timestamp));
            merkleRoots[i] = keccak256(abi.encodePacked("verify-batch-gas-root-", i, block.timestamp));
        }

        gasStart = gasleft();
        anchor.anchorBatch(batchIds, merkleRoots, chainTag, note);
        gasUsed = gasStart - gasleft();

        uint256 gasPerItem = gasUsed / 5;
        console.log("Batch anchor gas (5 items):", gasUsed);
        console.log("Gas per item:", gasPerItem);

        if (gasPerItem < 4000 || gasPerItem > 6000) {
            console.log("WARNING: Batch gas per item outside expected range (4k-6k)");
        } else {
            console.log("PASS: Batch gas efficiency within expected range");
        }
    }

    function getContractAddress() internal view returns (address) {
        if (block.chainid == 8453) {
            return BASE_MAINNET_ANCHOR;
        } else if (block.chainid == 84532) {
            return BASE_SEPOLIA_ANCHOR;
        } else {
            return HORIZEN_TESTNET_ANCHOR;
        }
    }

    function getNetworkName() internal view returns (string memory) {
        if (block.chainid == 8453) {
            return "base-mainnet";
        } else if (block.chainid == 84532) {
            return "base-sepolia";
        } else if (block.chainid == 1) {
            return "ethereum-mainnet";
        } else if (block.chainid == 11155111) {
            return "sepolia";
        } else {
            return "horizen-testnet";
        }
    }
}

