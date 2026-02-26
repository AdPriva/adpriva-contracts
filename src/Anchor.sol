// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Anchor
 * @dev Simple anchoring contract for AdPriva proof batches on Horizen
 *
 * Access Control: Anyone can call anchor() - this is intentional.
 * The contract serves as a neutral public anchoring log. AdPriva's backend
 * filters events by the authorized submitter address, ignoring unauthorized anchors.
 *
 * Deployment (check latest endpoints in Horizen docs):
 * - Mainnet: Horizen on Base (ZEN ERC-20 on Base mainnet, chainId 8453)
 * - Testnet: Horizen on Base Sepolia (chainId 84532) or Horizen testnet appchain
 *   Docs: https://horizen-2-docs.horizen.io/
 *
 * Internal (AdPriva):
 * - Current testnet: Horizen testnet appchain (Caldera)
 *   Explorer: https://horizen-testnet.explorer.caldera.xyz/
 * - Current mainnet: TBD (will migrate to Base mainnet for production)
 *
 * Usage:
 * - Call anchor() with batch ID hash, Merkle root, chain tag, and optional note
 * - Each anchor emits an Anchored event with all details + timestamp
 * - Events are indexed and queryable via blockchain explorers
 *
 * Gas Cost: ~50,000-70,000 gas per anchor
 *
 * Security Limits:
 * - Maximum batch size: 100 items (DoS prevention)
 * - Maximum chainTag length: 64 bytes
 * - Maximum note length: 256 bytes
 */
contract Anchor {
    // Constants for input validation
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant MAX_CHAIN_TAG_LENGTH = 64;
    uint256 public constant MAX_NOTE_LENGTH = 256;
    event Anchored(
        bytes32 indexed batchIdHash,
        bytes32 indexed merkleRoot,
        address indexed submitter,
        uint256 timestamp,
        string chainTag,
        string note
    );

    /**
     * @dev Anchor a proof batch Merkle root to the blockchain
     * @param batchIdHash Keccak256 hash of the batch ID
     * @param merkleRoot 32-byte Merkle root of the proof batch
     * @param chainTag Chain identifier (e.g., "horizen-testnet")
     * @param note Optional metadata (e.g., "AdPriva Proof Batch")
     * @return The batchIdHash for confirmation
     */
    function anchor(bytes32 batchIdHash, bytes32 merkleRoot, string calldata chainTag, string calldata note)
        external
        returns (bytes32)
    {
        require(batchIdHash != bytes32(0), "Invalid batchIdHash");
        require(merkleRoot != bytes32(0), "Invalid merkleRoot");
        require(bytes(chainTag).length > 0, "Empty chainTag");
        require(bytes(chainTag).length <= MAX_CHAIN_TAG_LENGTH, "chainTag too long");
        require(bytes(note).length <= MAX_NOTE_LENGTH, "note too long");

        emit Anchored(batchIdHash, merkleRoot, msg.sender, block.timestamp, chainTag, note);

        return batchIdHash;
    }

    /**
     * @dev Batch anchor multiple proof batches in a single transaction
     * @param batchIdHashes Array of batch ID hashes
     * @param merkleRoots Array of Merkle roots
     * @param chainTag Chain identifier for all batches
     * @param note Optional metadata
     */
    function anchorBatch(
        bytes32[] calldata batchIdHashes,
        bytes32[] calldata merkleRoots,
        string calldata chainTag,
        string calldata note
    ) external {
        require(batchIdHashes.length > 0, "Empty array");
        require(batchIdHashes.length <= MAX_BATCH_SIZE, "Batch too large");
        require(batchIdHashes.length == merkleRoots.length, "Array length mismatch");
        require(bytes(chainTag).length > 0, "Empty chainTag");
        require(bytes(chainTag).length <= MAX_CHAIN_TAG_LENGTH, "chainTag too long");
        require(bytes(note).length <= MAX_NOTE_LENGTH, "note too long");

        for (uint256 i = 0; i < batchIdHashes.length;) {
            require(batchIdHashes[i] != bytes32(0), "Invalid batchIdHash");
            require(merkleRoots[i] != bytes32(0), "Invalid merkleRoot");

            emit Anchored(batchIdHashes[i], merkleRoots[i], msg.sender, block.timestamp, chainTag, note);
            unchecked {
                ++i;
            }
        }
    }
}
