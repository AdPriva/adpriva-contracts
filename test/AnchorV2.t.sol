// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {AnchorV2} from "../src/AnchorV2.sol";

contract AnchorV2Test is Test {
    AnchorV2 public anchor;

    address public owner = address(0xA11CE);
    address public submitter = address(0x5B);
    address public stranger = address(0xBAD);

    uint16 public constant VERSION = 1;
    bytes32 public constant ROOT = keccak256("root-1");

    event BatchAnchored(
        bytes32 indexed batchId, bytes32 indexed root, uint16 indexed protocolVersion, address submitter
    );
    event SubmitterSet(address indexed submitter, bool allowed);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        address[] memory submitters = new address[](1);
        submitters[0] = submitter;
        anchor = new AnchorV2(owner, submitters);
    }

    function _expectedBatchId(uint16 version, bytes32 root) internal view returns (bytes32) {
        return keccak256(abi.encode(version, block.chainid, address(anchor), root));
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_SetsOwnerAndSubmitters() public view {
        assertEq(anchor.owner(), owner);
        assertEq(anchor.pendingOwner(), address(0));
        assertTrue(anchor.isSubmitter(submitter));
        assertFalse(anchor.isSubmitter(stranger));
        assertFalse(anchor.paused());
    }

    function test_Constructor_EmitsSubmitterSetAndOwnershipTransferred() public {
        address[] memory submitters = new address[](1);
        submitters[0] = submitter;
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(0), owner);
        vm.expectEmit(true, false, false, true);
        emit SubmitterSet(submitter, true);
        new AnchorV2(owner, submitters);
    }

    function test_RevertWhen_ConstructorOwnerIsZero() public {
        vm.expectRevert(AnchorV2.ZeroAddress.selector);
        new AnchorV2(address(0), new address[](0));
    }

    function test_RevertWhen_ConstructorSubmitterIsZero() public {
        address[] memory submitters = new address[](1);
        vm.expectRevert(AnchorV2.ZeroAddress.selector);
        new AnchorV2(owner, submitters);
    }

    /*//////////////////////////////////////////////////////////////
                              ANCHOR
    //////////////////////////////////////////////////////////////*/

    function test_Anchor_EmitsStoresAndReturnsDerivedBatchId() public {
        bytes32 expected = _expectedBatchId(VERSION, ROOT);
        vm.roll(1234);

        vm.expectEmit(true, true, true, true, address(anchor));
        emit BatchAnchored(expected, ROOT, VERSION, submitter);
        vm.prank(submitter);
        bytes32 batchId = anchor.anchor(VERSION, ROOT);

        assertEq(batchId, expected);
        assertEq(anchor.anchoredAtBlock(batchId), 1234);
    }

    function test_BatchIdOf_MatchesTheAnchoredId() public {
        vm.prank(submitter);
        bytes32 batchId = anchor.anchor(VERSION, ROOT);
        assertEq(anchor.batchIdOf(VERSION, ROOT), batchId);
    }

    /// The vector off-chain code (worker, explorer) recomputes: keccak256(abi.encode(uint16 version,
    /// uint256 chainId, address anchorContract, bytes32 root)). Expected values computed with
    /// `cast keccak $(cast abi-encode "f(uint16,uint256,address,bytes32)" ...)` and ethers v6.
    function test_BatchIdOf_DerivationVector() public {
        address at = 0xa2c0000000000000000000000000000000000002;
        bytes32 root = 0x2b2ba0b8a1f1a2c6e0f5ad4ad66b9b3f2a3f0e9f8c7d6b5a4938271605f4e3d2;
        vm.chainId(26514); // Horizen mainnet
        deployCodeTo("AnchorV2.sol:AnchorV2", abi.encode(owner, new address[](0)), at);

        assertEq(AnchorV2(at).batchIdOf(1, root), 0xfdc149d3bd16781cc180cd71699ae66adfa16e53a23369742654cbbef6707de7);
        assertEq(AnchorV2(at).batchIdOf(2, root), 0xbfd762042824a702299d571f2cd543ea0e341013cf6c3354eb8072d435583d93);
    }

    function test_BatchIdOf_DependsOnChainId() public {
        bytes32 here = anchor.batchIdOf(VERSION, ROOT);
        vm.chainId(block.chainid + 1);
        assertTrue(anchor.batchIdOf(VERSION, ROOT) != here);
    }

    function test_RevertWhen_RootAnchoredTwice() public {
        vm.prank(submitter);
        bytes32 batchId = anchor.anchor(VERSION, ROOT);
        uint256 firstBlock = block.number;
        vm.roll(firstBlock + 10);

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.AlreadyAnchored.selector, batchId, firstBlock));
        vm.prank(submitter);
        anchor.anchor(VERSION, ROOT);
    }

    function test_RevertWhen_AnotherSubmitterAnchorsTheSameRoot() public {
        address second = address(0x5C);
        vm.prank(owner);
        anchor.setSubmitter(second, true);

        vm.prank(submitter);
        bytes32 batchId = anchor.anchor(VERSION, ROOT);

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.AlreadyAnchored.selector, batchId, block.number));
        vm.prank(second);
        anchor.anchor(VERSION, ROOT);
    }

    function test_Anchor_SameRootUnderAnotherVersionIsADistinctBatch() public {
        vm.startPrank(submitter);
        bytes32 v1 = anchor.anchor(1, ROOT);
        bytes32 v2 = anchor.anchor(2, ROOT);
        vm.stopPrank();
        assertTrue(v1 != v2);
    }

    function test_RevertWhen_RootIsZero() public {
        vm.expectRevert(AnchorV2.ZeroRoot.selector);
        vm.prank(submitter);
        anchor.anchor(VERSION, bytes32(0));
    }

    function test_RevertWhen_ProtocolVersionIsZero() public {
        vm.expectRevert(AnchorV2.ZeroProtocolVersion.selector);
        vm.prank(submitter);
        anchor.anchor(0, ROOT);
    }

    /*//////////////////////////////////////////////////////////////
                         SUBMITTER ALLOWLIST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_CallerIsNotASubmitter() public {
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotSubmitter.selector, stranger));
        vm.prank(stranger);
        anchor.anchor(VERSION, ROOT);
    }

    function test_RevertWhen_OwnerIsNotASubmitter() public {
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotSubmitter.selector, owner));
        vm.prank(owner);
        anchor.anchor(VERSION, ROOT);
    }

    function test_RevertWhen_SubmitterWasRemoved() public {
        vm.expectEmit(true, false, false, true);
        emit SubmitterSet(submitter, false);
        vm.prank(owner);
        anchor.setSubmitter(submitter, false);

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotSubmitter.selector, submitter));
        vm.prank(submitter);
        anchor.anchor(VERSION, ROOT);
    }

    function test_SetSubmitter_AddedSubmitterCanAnchor() public {
        vm.prank(owner);
        anchor.setSubmitter(stranger, true);
        vm.prank(stranger);
        anchor.anchor(VERSION, ROOT);
        assertTrue(anchor.anchoredAtBlock(anchor.batchIdOf(VERSION, ROOT)) != 0);
    }

    function test_RevertWhen_SetSubmitterZeroAddress() public {
        vm.expectRevert(AnchorV2.ZeroAddress.selector);
        vm.prank(owner);
        anchor.setSubmitter(address(0), true);
    }

    /*//////////////////////////////////////////////////////////////
                               PAUSE
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Paused() public {
        vm.expectEmit(false, false, false, true);
        emit Paused(owner);
        vm.prank(owner);
        anchor.pause();
        assertTrue(anchor.paused());

        vm.expectRevert(AnchorV2.ContractPaused.selector);
        vm.prank(submitter);
        anchor.anchor(VERSION, ROOT);
    }

    function test_Unpause_RestoresAnchoring() public {
        vm.startPrank(owner);
        anchor.pause();
        vm.expectEmit(false, false, false, true);
        emit Unpaused(owner);
        anchor.unpause();
        vm.stopPrank();

        vm.prank(submitter);
        anchor.anchor(VERSION, ROOT);
        assertFalse(anchor.paused());
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER ADMIN
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_NonOwnerSetsSubmitter() public {
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, submitter));
        vm.prank(submitter);
        anchor.setSubmitter(stranger, true);
    }

    function test_RevertWhen_NonOwnerPauses() public {
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, submitter));
        vm.prank(submitter);
        anchor.pause();
    }

    function test_RevertWhen_NonOwnerUnpauses() public {
        vm.prank(owner);
        anchor.pause();
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, stranger));
        vm.prank(stranger);
        anchor.unpause();
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, stranger));
        vm.prank(stranger);
        anchor.transferOwnership(stranger);
    }

    function test_TransferOwnership_IsTwoStep() public {
        address multisig = address(0x5AFE);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(owner, multisig);
        vm.prank(owner);
        anchor.transferOwnership(multisig);
        assertEq(anchor.owner(), owner, "owner unchanged until accepted");
        assertEq(anchor.pendingOwner(), multisig);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(owner, multisig);
        vm.prank(multisig);
        anchor.acceptOwnership();
        assertEq(anchor.owner(), multisig);
        assertEq(anchor.pendingOwner(), address(0));

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, owner));
        vm.prank(owner);
        anchor.pause();
    }

    function test_RevertWhen_NonPendingOwnerAccepts() public {
        vm.prank(owner);
        anchor.transferOwnership(address(0x5AFE));
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotPendingOwner.selector, stranger));
        vm.prank(stranger);
        anchor.acceptOwnership();
    }

    function test_TransferOwnership_ToZeroCancelsAPendingTransfer() public {
        address multisig = address(0x5AFE);
        vm.startPrank(owner);
        anchor.transferOwnership(multisig);
        anchor.transferOwnership(address(0));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotPendingOwner.selector, multisig));
        vm.prank(multisig);
        anchor.acceptOwnership();
        assertEq(anchor.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                                GAS
    //////////////////////////////////////////////////////////////*/

    /// Whole-transaction gas of one first-time anchor (intrinsic 21,000 + calldata + execution; it
    /// equals the receipt gasUsed on anvil, 51,151). Recorded in snapshots/AnchorV2.json; the bound is
    /// a regression guard. 22,100 of it is the dedup slot, 4,200 the cold allowlist and pause reads.
    function test_Gas_AnchorStaysUnderBudget() public {
        vm.prank(submitter);
        anchor.anchor(VERSION, ROOT);
        uint256 used = vm.snapshotGasLastCall("AnchorV2", "anchor");
        assertLe(used, 52_000);
    }

    /*//////////////////////////////////////////////////////////////
                               FUZZ
    //////////////////////////////////////////////////////////////*/

    function testFuzz_AnchorsOnceThenReverts(uint16 version, bytes32 root) public {
        vm.assume(version != 0 && root != bytes32(0));

        vm.prank(submitter);
        bytes32 batchId = anchor.anchor(version, root);
        assertEq(batchId, _expectedBatchId(version, root));
        assertEq(anchor.anchoredAtBlock(batchId), block.number);

        vm.expectRevert(abi.encodeWithSelector(AnchorV2.AlreadyAnchored.selector, batchId, block.number));
        vm.prank(submitter);
        anchor.anchor(version, root);
    }

    function testFuzz_RevertWhen_CallerIsNotASubmitter(address caller, uint16 version, bytes32 root) public {
        vm.assume(caller != submitter);
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotSubmitter.selector, caller));
        vm.prank(caller);
        anchor.anchor(version, root);
    }

    function testFuzz_RevertWhen_NonOwnerCallsAdmin(address caller) public {
        vm.assume(caller != owner);
        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, caller));
        anchor.setSubmitter(caller, true);
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, caller));
        anchor.pause();
        vm.expectRevert(abi.encodeWithSelector(AnchorV2.NotOwner.selector, caller));
        anchor.transferOwnership(caller);
        vm.stopPrank();
    }
}
