# ADR-003: AnchorV2, contract-derived ids, dedup and a submitter allowlist

**Status:** Accepted (contract merged, not deployed)
**Date:** 2026-10-16
**Context issues:** AdPriva/proofs#43 (Gate A, option B), AdPriva/proofs#48

## Context

Gate A chose option B: proof batches are anchored as plain Merkle roots on Horizen, with no zkVerify. The
on-chain anchor therefore carries the whole public claim, and v1 (`Anchor.sol`, ADR-001) cannot carry it:
- the caller picks `batchIdHash`
- nothing stops the same root from being anchored again later
- anyone can call it, so readers must trust an off-chain filter on the sender

## Decision

Add `AnchorV2.sol` next to v1 (v1 stays the source of the deployed contract):

- `batchId = keccak256(abi.encode(uint16 protocolVersion, block.chainid, address(this), root))`, derived by the contract.
- `anchoredAtBlock[batchId]` is set on the first anchor, and a second anchor reverts.
- `isSubmitter` allowlist; owner-administered `pause`; two-step ownership transfer to a multisig.
- Immutable, no proxy (ADR-002 still holds).

This supersedes ADR-001's permissionless choice **for v2 only**.

## Consequences

- An anchor costs 51,151 gas instead of ~28-29k: the dedup slot is 22,100 and the allowlist and pause reads are 4,200. At Horizen prices this is negligible (about 5.6e-8 ETH).
- Re-anchoring the same root reverts, so the worker must treat `AlreadyAnchored` as success and reconcile.
- The owner is a key-management item: the multisig holders, the threshold and the deployer key are owner decisions.

## Alternatives considered

- **Single submitter packed with `paused` in one slot:** saves 2,100 gas, but a signer rotation could not overlap old and new keys. Rejected.
- **Caller-supplied batch id with dedup:** the id still means whatever the caller says. Rejected.
