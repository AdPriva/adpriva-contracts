// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title AnchorV2
 * @notice Anchors AdPriva batch Merkle roots, at most once each, from an allowlist of submitters.
 *
 * v1 (Anchor.sol, deployed on Horizen) only emits an event: the caller picks the batch id, the same
 * root can be anchored any number of times, and anyone can call it. v2 adds, for Gate A option B
 * (AdPriva/proofs#43, AdPriva/proofs#48):
 *
 * - A contract-derived batch id. `batchId = keccak256(abi.encode(protocolVersion, block.chainid,
 *   address(this), root))`, so it cannot be chosen by the caller and anyone can recompute it
 *   off-chain from the root, the chain and this contract's address.
 * - Storage dedup. `anchoredAtBlock[batchId]` records the first anchor; a second one reverts, so
 *   the first block a root appears in is the only one.
 * - A submitter allowlist (the anchor-worker signer), a pause switch, and an owner (intended to be
 *   a multisig) with two-step transfer. Every state change emits an event.
 *
 * `protocolVersion` names the leaf and tree scheme the root commits to (for example the Poseidon
 * view-proof tree or the sha256 consent tree, and later the content leaves of AdPriva/proofs#36).
 * The contract treats it as an opaque non-zero tag: the same root under two versions is two batches.
 *
 * Immutable, like v1 (docs/anchor/ADR-002): no proxy, no upgrade path, no funds held.
 */
contract AnchorV2 {
    error NotOwner(address caller);
    error NotPendingOwner(address caller);
    error NotSubmitter(address caller);
    error ContractPaused();
    error AlreadyAnchored(bytes32 batchId, uint256 anchoredAtBlock);
    error ZeroRoot();
    error ZeroProtocolVersion();
    error ZeroAddress();

    event BatchAnchored(
        bytes32 indexed batchId, bytes32 indexed root, uint16 indexed protocolVersion, address submitter
    );
    event SubmitterSet(address indexed submitter, bool allowed);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // owner and paused share one storage slot.
    address public owner;
    bool public paused;
    address public pendingOwner;
    mapping(address => bool) public isSubmitter;
    /// Block number of the first anchor of a batch id; 0 means never anchored.
    mapping(bytes32 => uint256) public anchoredAtBlock;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    constructor(address initialOwner, address[] memory initialSubmitters) {
        if (initialOwner == address(0)) revert ZeroAddress();
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
        for (uint256 i = 0; i < initialSubmitters.length; ++i) {
            _setSubmitter(initialSubmitters[i], true);
        }
    }

    /**
     * @notice Anchor `root` once under `protocolVersion`.
     * @return batchId The contract-derived id, see batchIdOf.
     */
    function anchor(uint16 protocolVersion, bytes32 root) external returns (bytes32 batchId) {
        if (paused) revert ContractPaused();
        if (!isSubmitter[msg.sender]) revert NotSubmitter(msg.sender);
        if (protocolVersion == 0) revert ZeroProtocolVersion();
        if (root == bytes32(0)) revert ZeroRoot();

        batchId = batchIdOf(protocolVersion, root);
        uint256 firstBlock = anchoredAtBlock[batchId];
        if (firstBlock != 0) revert AlreadyAnchored(batchId, firstBlock);

        anchoredAtBlock[batchId] = block.number;
        emit BatchAnchored(batchId, root, protocolVersion, msg.sender);
    }

    /// @notice The batch id `anchor` derives for `root` under `protocolVersion` on this deployment.
    function batchIdOf(uint16 protocolVersion, bytes32 root) public view returns (bytes32) {
        return keccak256(abi.encode(protocolVersion, block.chainid, address(this), root));
    }

    function setSubmitter(address submitter, bool allowed) external onlyOwner {
        _setSubmitter(submitter, allowed);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Start a transfer; `newOwner` must call acceptOwnership. address(0) cancels a pending one.
    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner(msg.sender);
        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(previousOwner, msg.sender);
    }

    function _setSubmitter(address submitter, bool allowed) private {
        if (submitter == address(0)) revert ZeroAddress();
        isSubmitter[submitter] = allowed;
        emit SubmitterSet(submitter, allowed);
    }
}
