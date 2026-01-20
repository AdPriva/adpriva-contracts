// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Anchor} from "../src/Anchor.sol";

contract AnchorTest is Test {
    Anchor public anchor;

    address public deployer = address(0x1);
    address public submitter1 = address(0x2);
    address public submitter2 = address(0x3);

    event Anchored(
        bytes32 indexed batchIdHash,
        bytes32 indexed merkleRoot,
        address indexed submitter,
        uint256 timestamp,
        string chainTag,
        string note
    );

    function setUp() public {
        vm.prank(deployer);
        anchor = new Anchor();
    }

    /*//////////////////////////////////////////////////////////////
                        SINGLE ANCHOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Anchor_Success() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");
        string memory chainTag = "horizen-testnet";
        string memory note = "AdPriva Proof Batch";

        vm.startPrank(submitter1);

        vm.expectEmit(true, true, true, true);
        emit Anchored(batchId, merkleRoot, submitter1, block.timestamp, chainTag, note);

        bytes32 result = anchor.anchor(batchId, merkleRoot, chainTag, note);

        assertEq(result, batchId, "Should return batchIdHash");

        vm.stopPrank();
    }

    function test_Anchor_MultipleDifferentBatches() public {
        bytes32 batchId1 = keccak256("batch1");
        bytes32 merkleRoot1 = keccak256("root1");

        bytes32 batchId2 = keccak256("batch2");
        bytes32 merkleRoot2 = keccak256("root2");

        vm.startPrank(submitter1);

        anchor.anchor(batchId1, merkleRoot1, "horizen-testnet", "First batch");
        anchor.anchor(batchId2, merkleRoot2, "horizen-testnet", "Second batch");

        vm.stopPrank();
    }

    function test_Anchor_SameBatchIdDifferentRoot() public {
        // Should allow same batchId with different merkle root (not recommended but not prevented)
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot1 = keccak256("root1");
        bytes32 merkleRoot2 = keccak256("root2");

        vm.startPrank(submitter1);

        anchor.anchor(batchId, merkleRoot1, "horizen-testnet", "First anchor");
        anchor.anchor(batchId, merkleRoot2, "horizen-testnet", "Second anchor");

        vm.stopPrank();
    }

    function test_Anchor_EmptyNote() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        vm.prank(submitter1);
        bytes32 result = anchor.anchor(batchId, merkleRoot, "horizen-testnet", "");

        assertEq(result, batchId);
    }

    function test_Anchor_EmptyChainTag_Reverts() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        vm.prank(submitter1);
        vm.expectRevert("Empty chainTag");
        anchor.anchor(batchId, merkleRoot, "", "Test note");
    }

    function test_Anchor_ZeroHashes_Reverts() public {
        bytes32 batchId = bytes32(0);
        bytes32 merkleRoot = keccak256("root1");

        vm.prank(submitter1);
        vm.expectRevert("Invalid batchIdHash");
        anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Zero batch hash");
    }

    function test_Anchor_ZeroMerkleRoot_Reverts() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = bytes32(0);

        vm.prank(submitter1);
        vm.expectRevert("Invalid merkleRoot");
        anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Zero merkle root");
    }

    function test_Anchor_DifferentSubmitters() public {
        bytes32 batchId1 = keccak256("batch1");
        bytes32 merkleRoot1 = keccak256("root1");

        bytes32 batchId2 = keccak256("batch2");
        bytes32 merkleRoot2 = keccak256("root2");

        vm.prank(submitter1);
        anchor.anchor(batchId1, merkleRoot1, "horizen-testnet", "Submitter 1");

        vm.prank(submitter2);
        anchor.anchor(batchId2, merkleRoot2, "horizen-testnet", "Submitter 2");
    }

    function test_Anchor_LongChainTag_Reverts() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        // Create a chainTag longer than 64 bytes
        string memory longChainTag =
            "horizen-testnet-very-long-chain-tag-name-that-exceeds-maximum-allowed-length-limit";

        vm.prank(submitter1);
        vm.expectRevert("chainTag too long");
        anchor.anchor(batchId, merkleRoot, longChainTag, "Test");
    }

    function test_Anchor_LongNote_Reverts() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        // Create a note longer than 256 bytes
        string memory longNote =
            "This is a very long note that contains a lot of metadata about the proof batch including timestamps, versions, and other relevant information that might be useful for debugging or auditing purposes in the future. This note is intentionally made very long to exceed the 256 byte limit.";

        vm.prank(submitter1);
        vm.expectRevert("note too long");
        anchor.anchor(batchId, merkleRoot, "horizen-testnet", longNote);
    }

    function test_Anchor_ValidLongStrings() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        // 64 bytes exactly - should succeed
        string memory maxChainTag = "1234567890123456789012345678901234567890123456789012345678901234";
        // 256 bytes exactly - should succeed
        string memory maxNote =
            "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456";

        vm.prank(submitter1);
        bytes32 result = anchor.anchor(batchId, merkleRoot, maxChainTag, maxNote);

        assertEq(result, batchId);
    }

    function test_Anchor_CorrectTimestamp() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        uint256 expectedTimestamp = block.timestamp;

        vm.expectEmit(true, true, true, true);
        emit Anchored(batchId, merkleRoot, address(this), expectedTimestamp, "horizen-testnet", "Test");

        anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Test");
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH ANCHOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AnchorBatch_Success() public {
        bytes32[] memory batchIds = new bytes32[](3);
        batchIds[0] = keccak256("batch1");
        batchIds[1] = keccak256("batch2");
        batchIds[2] = keccak256("batch3");

        bytes32[] memory merkleRoots = new bytes32[](3);
        merkleRoots[0] = keccak256("root1");
        merkleRoots[1] = keccak256("root2");
        merkleRoots[2] = keccak256("root3");

        vm.startPrank(submitter1);

        // Expect all 3 events
        for (uint256 i = 0; i < 3; i++) {
            vm.expectEmit(true, true, true, true);
            emit Anchored(batchIds[i], merkleRoots[i], submitter1, block.timestamp, "horizen-testnet", "Batch anchor");
        }

        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Batch anchor");

        vm.stopPrank();
    }

    function test_AnchorBatch_SingleItem() public {
        bytes32[] memory batchIds = new bytes32[](1);
        batchIds[0] = keccak256("batch1");

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = keccak256("root1");

        vm.prank(submitter1);
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Single item");
    }

    function test_AnchorBatch_EmptyArrays_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](0);
        bytes32[] memory merkleRoots = new bytes32[](0);

        vm.prank(submitter1);
        vm.expectRevert("Empty array");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Empty arrays");
    }

    function test_AnchorBatch_LargeBatch() public {
        uint256 size = 50;
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Large batch");
    }

    function test_AnchorBatch_RevertOnLengthMismatch() public {
        bytes32[] memory batchIds = new bytes32[](3);
        batchIds[0] = keccak256("batch1");
        batchIds[1] = keccak256("batch2");
        batchIds[2] = keccak256("batch3");

        bytes32[] memory merkleRoots = new bytes32[](2);
        merkleRoots[0] = keccak256("root1");
        merkleRoots[1] = keccak256("root2");

        vm.prank(submitter1);
        vm.expectRevert("Array length mismatch");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Mismatch test");
    }

    function test_AnchorBatch_RevertOnLengthMismatch_Reverse() public {
        bytes32[] memory batchIds = new bytes32[](2);
        batchIds[0] = keccak256("batch1");
        batchIds[1] = keccak256("batch2");

        bytes32[] memory merkleRoots = new bytes32[](3);
        merkleRoots[0] = keccak256("root1");
        merkleRoots[1] = keccak256("root2");
        merkleRoots[2] = keccak256("root3");

        vm.prank(submitter1);
        vm.expectRevert("Array length mismatch");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Mismatch test");
    }

    function test_AnchorBatch_MaxBatchSize() public {
        uint256 size = 100; // MAX_BATCH_SIZE
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Max batch");
    }

    function test_AnchorBatch_ExceedMaxBatchSize_Reverts() public {
        uint256 size = 101; // Exceeds MAX_BATCH_SIZE
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        vm.expectRevert("Batch too large");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Too large");
    }

    function test_AnchorBatch_ZeroBatchIdHash_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](2);
        batchIds[0] = keccak256("batch1");
        batchIds[1] = bytes32(0); // Invalid zero hash

        bytes32[] memory merkleRoots = new bytes32[](2);
        merkleRoots[0] = keccak256("root1");
        merkleRoots[1] = keccak256("root2");

        vm.prank(submitter1);
        vm.expectRevert("Invalid batchIdHash");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Zero batch hash");
    }

    function test_AnchorBatch_ZeroMerkleRoot_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](2);
        batchIds[0] = keccak256("batch1");
        batchIds[1] = keccak256("batch2");

        bytes32[] memory merkleRoots = new bytes32[](2);
        merkleRoots[0] = keccak256("root1");
        merkleRoots[1] = bytes32(0); // Invalid zero merkle root

        vm.prank(submitter1);
        vm.expectRevert("Invalid merkleRoot");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Zero merkle root");
    }

    function test_AnchorBatch_EmptyChainTag_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](1);
        batchIds[0] = keccak256("batch1");

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = keccak256("root1");

        vm.prank(submitter1);
        vm.expectRevert("Empty chainTag");
        anchor.anchorBatch(batchIds, merkleRoots, "", "Test note");
    }

    function test_AnchorBatch_LongChainTag_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](1);
        batchIds[0] = keccak256("batch1");

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = keccak256("root1");

        string memory longChainTag =
            "horizen-testnet-very-long-chain-tag-name-that-exceeds-maximum-allowed-length-limit";

        vm.prank(submitter1);
        vm.expectRevert("chainTag too long");
        anchor.anchorBatch(batchIds, merkleRoots, longChainTag, "Test");
    }

    function test_AnchorBatch_LongNote_Reverts() public {
        bytes32[] memory batchIds = new bytes32[](1);
        batchIds[0] = keccak256("batch1");

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = keccak256("root1");

        string memory longNote =
            "This is a very long note that contains a lot of metadata about the proof batch including timestamps, versions, and other relevant information that might be useful for debugging or auditing purposes in the future. This note is intentionally made very long to exceed the 256 byte limit.";

        vm.prank(submitter1);
        vm.expectRevert("note too long");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", longNote);
    }

    /*//////////////////////////////////////////////////////////////
                        GAS BENCHMARK TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Gas_SingleAnchor() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        vm.prank(submitter1);
        uint256 gasBefore = gasleft();
        anchor.anchor(batchId, merkleRoot, "horizen-testnet", "AdPriva Proof Batch");
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for single anchor:", gasUsed);

        // Expected gas: ~50k-70k per contract comment
        assertLt(gasUsed, 80000, "Gas usage should be under 80k");
    }

    function test_Gas_BatchAnchor_10Items() public {
        uint256 size = 10;
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        uint256 gasBefore = gasleft();
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "AdPriva Proof Batch");
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for 10-item batch:", gasUsed);
        console.log("Gas per item:", gasUsed / size);

        assertLt(gasUsed / size, 70000, "Gas per item in batch should be efficient");
    }

    function test_Gas_BatchAnchor_50Items() public {
        uint256 size = 50;
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        uint256 gasBefore = gasleft();
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "AdPriva Proof Batch");
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for 50-item batch:", gasUsed);
        console.log("Gas per item:", gasUsed / size);
    }

    function test_Gas_CompareSingleVsBatch() public {
        // Single anchors
        uint256 totalGasSingle = 0;
        for (uint256 i = 0; i < 10; i++) {
            bytes32 batchId = keccak256(abi.encodePacked("batch", i));
            bytes32 merkleRoot = keccak256(abi.encodePacked("root", i));

            vm.prank(submitter1);
            uint256 gasBefore = gasleft();
            anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Test");
            totalGasSingle += gasBefore - gasleft();
        }

        console.log("Total gas for 10 single anchors:", totalGasSingle);

        // Batch anchor
        bytes32[] memory batchIds = new bytes32[](10);
        bytes32[] memory merkleRoots = new bytes32[](10);

        for (uint256 i = 0; i < 10; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i + 100));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i + 100));
        }

        vm.prank(submitter1);
        uint256 gasBefore = gasleft();
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Test");
        uint256 gasBatch = gasBefore - gasleft();

        console.log("Total gas for 1 batch of 10:", gasBatch);
        console.log("Gas savings:", totalGasSingle - gasBatch);
        console.log("Savings percentage:", ((totalGasSingle - gasBatch) * 100) / totalGasSingle);

        assertLt(gasBatch, totalGasSingle, "Batch should be more efficient");
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_Anchor(bytes32 batchId, bytes32 merkleRoot, string calldata chainTag, string calldata note)
        public
    {
        // Assume valid inputs that pass our security validations
        vm.assume(batchId != bytes32(0));
        vm.assume(merkleRoot != bytes32(0));
        vm.assume(bytes(chainTag).length > 0 && bytes(chainTag).length <= 64);
        vm.assume(bytes(note).length <= 256);

        vm.prank(submitter1);
        bytes32 result = anchor.anchor(batchId, merkleRoot, chainTag, note);
        assertEq(result, batchId);
    }

    function testFuzz_AnchorBatch_ValidLengths(uint8 size) public {
        vm.assume(size > 0 && size <= 100);

        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Fuzz test");
    }

    function testFuzz_AnchorBatch_MismatchReverts(uint8 size1, uint8 size2) public {
        vm.assume(size1 != size2);
        vm.assume(size1 > 0 && size1 <= 100);
        vm.assume(size2 > 0 && size2 <= 100);

        bytes32[] memory batchIds = new bytes32[](size1);
        bytes32[] memory merkleRoots = new bytes32[](size2);

        for (uint256 i = 0; i < size1; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
        }

        for (uint256 i = 0; i < size2; i++) {
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        vm.expectRevert("Array length mismatch");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Fuzz test");
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Integration_BackendWorkflow() public {
        // Simulate backend workflow: aggregate proofs, create merkle root, anchor

        // Step 1: Backend aggregates 5 proofs into a batch
        bytes32[] memory proofHashes = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            proofHashes[i] = keccak256(abi.encodePacked("proof", i));
        }

        // Step 2: Calculate merkle root (simplified for test)
        bytes32 merkleRoot = keccak256(abi.encode(proofHashes));

        // Step 3: Create batch ID
        bytes32 batchId = keccak256(abi.encodePacked("batch", block.timestamp));

        // Step 4: Backend anchors to blockchain
        vm.prank(submitter1);
        bytes32 result = anchor.anchor(batchId, merkleRoot, "horizen-testnet", "AdPriva Proof Batch v1.0");

        assertEq(result, batchId);
    }

    function test_Integration_MultipleSubmittersFiltering() public {
        // Simulate scenario where multiple submitters anchor, but backend only cares about authorized one

        bytes32 authorizedBatch = keccak256("authorized-batch");
        bytes32 authorizedRoot = keccak256("authorized-root");

        bytes32 unauthorizedBatch = keccak256("unauthorized-batch");
        bytes32 unauthorizedRoot = keccak256("unauthorized-root");

        // Authorized submitter
        vm.prank(submitter1);
        anchor.anchor(authorizedBatch, authorizedRoot, "horizen-testnet", "Official");

        // Unauthorized submitter (spam/test)
        vm.prank(submitter2);
        anchor.anchor(unauthorizedBatch, unauthorizedRoot, "horizen-testnet", "Spam");

        // Backend would filter events by submitter1 address only
        // This test demonstrates the permissionless design works as intended
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EdgeCase_MaxUint256Timestamp() public {
        // Warp to far future
        vm.warp(type(uint256).max);

        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        vm.prank(submitter1);
        anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Future test");
    }

    function test_EdgeCase_RepeatAnchoring() public {
        bytes32 batchId = keccak256("batch1");
        bytes32 merkleRoot = keccak256("root1");

        // Anchor same data 10 times (should all succeed)
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(submitter1);
            anchor.anchor(batchId, merkleRoot, "horizen-testnet", "Repeat test");
        }
    }

    function test_EdgeCase_VeryLargeArrayBoundary() public {
        // Test with 255 items (exceeds MAX_BATCH_SIZE, should revert)
        uint256 size = 255;
        bytes32[] memory batchIds = new bytes32[](size);
        bytes32[] memory merkleRoots = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            batchIds[i] = keccak256(abi.encodePacked("batch", i));
            merkleRoots[i] = keccak256(abi.encodePacked("root", i));
        }

        vm.prank(submitter1);
        vm.expectRevert("Batch too large");
        anchor.anchorBatch(batchIds, merkleRoots, "horizen-testnet", "Large batch test");
    }
}

