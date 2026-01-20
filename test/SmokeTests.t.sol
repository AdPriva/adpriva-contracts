// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Anchor} from "../src/Anchor.sol";

/**
 * @title SmokeTests
 * @notice Production smoke tests for deployed Anchor contracts
 * @dev Run these tests after deploying to testnet/mainnet to verify basic functionality
 *
 * Usage:
 *   forge test --match-contract SmokeTests --rpc-url <network> -vvv
 *
 * Example:
 *   forge test --match-contract SmokeTests --rpc-url base_sepolia -vvv
 */
contract SmokeTests is Test {
    // Set these addresses after deployment
    address constant BASE_MAINNET_ANCHOR = address(0); // TODO: Update after deployment
    address constant BASE_SEPOLIA_ANCHOR = address(0); // TODO: Update after deployment
    address constant HORIZEN_TESTNET_ANCHOR = address(0); // TODO: Update after deployment

    Anchor public anchor;
    address public testSubmitter;

    event Anchored(
        bytes32 indexed batchIdHash,
        bytes32 indexed merkleRoot,
        address indexed submitter,
        uint256 timestamp,
        string chainTag,
        string note
    );

    function setUp() public {
        // Determine which contract to test based on chain ID
        if (block.chainid == 8453) {
            // Base Mainnet
            require(BASE_MAINNET_ANCHOR != address(0), "Base mainnet address not set");
            anchor = Anchor(BASE_MAINNET_ANCHOR);
        } else if (block.chainid == 84532) {
            // Base Sepolia
            require(BASE_SEPOLIA_ANCHOR != address(0), "Base Sepolia address not set");
            anchor = Anchor(BASE_SEPOLIA_ANCHOR);
        } else if (block.chainid == 31337) {
            // Local Anvil/Foundry test - deploy a new contract
            anchor = new Anchor();
        } else {
            // Horizen Testnet or other
            require(HORIZEN_TESTNET_ANCHOR != address(0), "Horizen testnet address not set");
            anchor = Anchor(HORIZEN_TESTNET_ANCHOR);
        }

        testSubmitter = address(this);

        console.log("================================================");
        console.log("Running Smoke Tests");
        console.log("================================================");
        console.log("Network:", getNetworkName());
        console.log("Chain ID:", block.chainid);
        console.log("Anchor Contract:", address(anchor));
        console.log("Test Submitter:", testSubmitter);
        console.log("Block Number:", block.number);
        console.log("Timestamp:", block.timestamp);
        console.log("================================================");
    }

    /*//////////////////////////////////////////////////////////////
                        SMOKE TESTS - BASIC FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function testSmoke_ContractDeployed() public view {
        console.log("Test: Contract is deployed and has code");

        // Verify contract has code
        uint256 size;
        address contractAddr = address(anchor);
        assembly {
            size := extcodesize(contractAddr)
        }

        assertGt(size, 0, "Contract has no code");
        console.log("Contract size:", size, "bytes");
        console.log("PASS: Contract deployed successfully");
    }

    function testSmoke_SingleAnchor() public {
        console.log("Test: Single anchor submission");

        bytes32 batchId = keccak256(abi.encodePacked("smoke-test-batch-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("smoke-test-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Smoke Test - Single Anchor";

        uint256 gasStart = gasleft();

        vm.expectEmit(true, true, true, true);
        emit Anchored(batchId, merkleRoot, testSubmitter, block.timestamp, chainTag, note);

        bytes32 result = anchor.anchor(batchId, merkleRoot, chainTag, note);

        uint256 gasUsed = gasStart - gasleft();

        assertEq(result, batchId, "Incorrect batch ID returned");
        console.log("Gas used:", gasUsed);
        console.log("PASS: Single anchor successful");
    }

    function testSmoke_BatchAnchor() public {
        console.log("Test: Batch anchor submission");

        uint256 batchSize = 5;
        bytes32[] memory batchIds = new bytes32[](batchSize);
        bytes32[] memory merkleRoots = new bytes32[](batchSize);

        for (uint256 i = 0; i < batchSize; i++) {
            batchIds[i] = keccak256(abi.encodePacked("smoke-test-batch-", i, block.timestamp));
            merkleRoots[i] = keccak256(abi.encodePacked("smoke-test-root-", i, block.timestamp));
        }

        string memory chainTag = getNetworkName();
        string memory note = "Smoke Test - Batch Anchor";

        uint256 gasStart = gasleft();

        anchor.anchorBatch(batchIds, merkleRoots, chainTag, note);

        uint256 gasUsed = gasStart - gasleft();
        uint256 gasPerItem = gasUsed / batchSize;

        console.log("Batch size:", batchSize);
        console.log("Total gas used:", gasUsed);
        console.log("Gas per item:", gasPerItem);
        console.log("PASS: Batch anchor successful");
    }

    function testSmoke_EventVerification() public {
        console.log("Test: Event emission verification");

        bytes32 batchId = keccak256(abi.encodePacked("smoke-test-event-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("smoke-test-event-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Smoke Test - Event Verification";

        vm.recordLogs();

        anchor.anchor(batchId, merkleRoot, chainTag, note);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertGt(logs.length, 0, "No events emitted");

        // Verify the Anchored event
        Vm.Log memory anchorLog = logs[0];
        assertEq(anchorLog.topics.length, 4, "Incorrect number of indexed parameters");
        assertEq(
            anchorLog.topics[0],
            keccak256("Anchored(bytes32,bytes32,address,uint256,string,string)"),
            "Incorrect event signature"
        );
        assertEq(anchorLog.topics[1], batchId, "Incorrect batchIdHash");
        assertEq(anchorLog.topics[2], merkleRoot, "Incorrect merkleRoot");
        assertEq(anchorLog.topics[3], bytes32(uint256(uint160(testSubmitter))), "Incorrect submitter");

        console.log("Events emitted:", logs.length);
        console.log("PASS: Event verification successful");
    }

    function testSmoke_GasCostValidation() public {
        console.log("Test: Gas cost within expected range");

        bytes32 batchId = keccak256(abi.encodePacked("smoke-test-gas-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("smoke-test-gas-root-", block.timestamp));
        string memory chainTag = getNetworkName();
        string memory note = "Smoke Test - Gas Validation";

        uint256 gasStart = gasleft();
        anchor.anchor(batchId, merkleRoot, chainTag, note);
        uint256 gasUsed = gasStart - gasleft();

        // Expected gas range: In test environment, gas measurements are lower
        // Real transaction gas costs are typically 50k-70k with full transaction overhead
        // But gasleft() measures just execution gas, which is typically 4k-20k
        assertGt(gasUsed, 2000, "Gas usage suspiciously low");
        assertLt(gasUsed, 150000, "Gas usage higher than expected");

        console.log("Gas used:", gasUsed);
        console.log("Note: Test environment measures execution gas only");
        console.log("PASS: Gas cost within acceptable range");
    }

    function testSmoke_RepeatedAnchors() public {
        console.log("Test: Multiple sequential anchors");

        string memory chainTag = getNetworkName();

        for (uint256 i = 0; i < 3; i++) {
            bytes32 batchId = keccak256(abi.encodePacked("smoke-test-repeat-", i, block.timestamp));
            bytes32 merkleRoot = keccak256(abi.encodePacked("smoke-test-repeat-root-", i, block.timestamp));
            string memory note = string(abi.encodePacked("Smoke Test - Repeat #", vm.toString(i)));

            anchor.anchor(batchId, merkleRoot, chainTag, note);
            console.log("Anchor", i + 1, "successful");
        }

        console.log("PASS: Multiple sequential anchors successful");
    }

    function testSmoke_EndToEndWorkflow() public {
        console.log("Test: End-to-end anchoring workflow");

        // Simulate backend workflow
        string memory chainTag = getNetworkName();

        // Step 1: Generate batch ID and merkle root
        bytes32 batchId = keccak256(abi.encodePacked("smoke-test-e2e-batch-", block.timestamp));
        bytes32 merkleRoot = keccak256(abi.encodePacked("smoke-test-e2e-root-", block.timestamp));
        string memory note = "Smoke Test - E2E Workflow";

        console.log("Step 1: Generated batch ID and merkle root");

        // Step 2: Submit anchor
        uint256 gasStart = gasleft();
        vm.recordLogs();

        bytes32 result = anchor.anchor(batchId, merkleRoot, chainTag, note);

        uint256 gasUsed = gasStart - gasleft();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        console.log("Step 2: Submitted anchor transaction");
        console.log("Gas used:", gasUsed);

        // Step 3: Verify result
        assertEq(result, batchId, "Batch ID mismatch");
        assertGt(logs.length, 0, "No events emitted");

        console.log("Step 3: Verified result");
        console.log("Events emitted:", logs.length);

        // Step 4: Decode and validate event data
        Vm.Log memory anchorLog = logs[0];
        (uint256 timestamp, string memory emittedChainTag, string memory emittedNote) =
            abi.decode(anchorLog.data, (uint256, string, string));

        assertEq(timestamp, block.timestamp, "Timestamp mismatch");
        assertEq(keccak256(bytes(emittedChainTag)), keccak256(bytes(chainTag)), "Chain tag mismatch");
        assertEq(keccak256(bytes(emittedNote)), keccak256(bytes(note)), "Note mismatch");

        console.log("Step 4: Validated event data");
        console.log("PASS: End-to-end workflow successful");
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                        SMOKE TEST SUMMARY
    //////////////////////////////////////////////////////////////*/

    function test_SmokeTestSummary() public view {
        console.log("");
        console.log("================================================");
        console.log("SMOKE TEST SUMMARY");
        console.log("================================================");
        console.log("Network:", getNetworkName());
        console.log("Chain ID:", block.chainid);
        console.log("Contract:", address(anchor));
        console.log("Block:", block.number);
        console.log("Timestamp:", block.timestamp);
        console.log("");
        console.log("All smoke tests should pass for production readiness");
        console.log("================================================");
    }
}

