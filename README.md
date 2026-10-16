# AdPriva Blockchain Contracts

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-orange.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-blue)](https://book.getfoundry.sh/)

> Blockchain contract for privacy-preserving proof anchoring on Horizen and EVM-compatible networks.

## Overview

### Anchor Contract (Production-Ready, Audited)

A simple, immutable smart contract for anchoring proof batch Merkle roots to blockchain networks. Designed for security, gas efficiency, and transparency.

- **Security Audited** - Professionally reviewed and verified
- **Immutable** - Cannot be modified after deployment
- **Permissionless** - Anyone can anchor
- **Gas Efficient** - ~50k gas per anchor, 92% savings with batching
- **Event-Only Storage** - No state variables, all data in events
- **Production Ready** - Deployed on Horizen blockchain

### AnchorV2 (merged, not deployed)

`src/AnchorV2.sol` is the next anchor contract for Gate A option B, direct Merkle anchoring
(AdPriva/proofs#43, AdPriva/proofs#48). It sits next to v1: `src/Anchor.sol` stays the source of the
contract deployed on Horizen (`0x7b6a7eb310d30c338c9ecb575f439c1a93fcb217`), which the anchor-worker
still calls.

**What v2 guarantees on-chain** (v1 guarantees none of these):

| Property | How |
|---|---|
| The batch id is not chosen by the caller | `batchId = keccak256(abi.encode(uint16 protocolVersion, uint256 block.chainid, address(this), bytes32 root))`, computed by the contract. `batchIdOf(version, root)` returns it. |
| A root is anchored at most once | `anchoredAtBlock[batchId]` stores the block of the first anchor. A second `anchor` of the same version and root reverts `AlreadyAnchored(batchId, firstBlock)`, whoever sends it. |
| Only AdPriva's signer can anchor | `isSubmitter` allowlist; anyone else reverts `NotSubmitter(caller)`. Readers no longer filter logs by sender. |
| Anchoring can be stopped | The owner can `pause()` and `unpause()`. While paused, `anchor` reverts `ContractPaused()`. |
| Admin is a multisig | `owner` sets submitters, pauses and starts transfers. A transfer is two-step: `transferOwnership(new)`, then `acceptOwnership()` from the new address. `address(0)` cancels a pending transfer. |
| Every state change is logged | `BatchAnchored(batchId, root, protocolVersion, submitter)`, `SubmitterSet`, `Paused`, `Unpaused`, `OwnershipTransferStarted`, `OwnershipTransferred`. |

**What it does not guarantee:**
- It proves that AdPriva published a root at a block. It does not prove what the leaves contain. That is the leaf design in AdPriva/proofs#36.
- It does not prove that the root is final on L1. Settlement is a separate status.
- `protocolVersion` names the leaf and tree scheme the root commits to. The contract treats it as an opaque tag that is not zero, so the same root under two versions is two batches. The numbering is set when the worker moves to v2.

**Recomputing a batch id off-chain** (vector from `test_BatchIdOf_DerivationVector`):

```js
// ethers v6
const id = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
  ['uint16', 'uint256', 'address', 'bytes32'],
  [1, 26514, '0xa2c0000000000000000000000000000000000002',
   '0x2b2ba0b8a1f1a2c6e0f5ad4ad66b9b3f2a3f0e9f8c7d6b5a4938271605f4e3d2']));
// 0xfdc149d3bd16781cc180cd71699ae66adfa16e53a23369742654cbbef6707de7
```

**Gas:** one first-time anchor uses **51,151 gas** for the whole transaction, measured as the receipt
`gasUsed` on anvil and recorded in `snapshots/AnchorV2.json` (`test_Gas_AnchorStaysUnderBudget`
guards it at 52,000 or less). The parts:
- 21,000 intrinsic
- 22,100 for the dedup slot
- 4,200 for the cold allowlist and pause reads
- about 2.1k for the event
- the rest is calldata and dispatch

v1 uses about 28-29k with no storage. At the Horizen gas price measured on 2026-10-16 (about 0.0011 gwei), that is about 5.6e-8 ETH per anchor.

**Deploying it is an owner item.** It needs:
1. **A deployer key**, funded on Horizen mainnet (chain 26514). It pays for the deployment and gets no rights on the contract.
2. **The multisig** (for example a Safe) that will own the contract, together with its holders and threshold.
3. **The submitter**: the anchor-worker signer, the address of the worker's `HORIZEN_MAINNET_PRIVATE_KEY`.

```bash
PRIVATE_KEY=… ANCHOR_V2_OWNER=<multisig> ANCHOR_V2_SUBMITTER=<worker signer> \
forge script script/DeployAnchorV2.s.sol:DeployAnchorV2 --rpc-url horizen_mainnet --broadcast
```

After the deployment, the worker has to call `anchor(uint16,bytes32)` on the new address. It must treat
`AlreadyAnchored` as "already done" and reconcile it against the stored block. The readers (api,
explorer) must decode `BatchAnchored`. Both are separate work under AdPriva/proofs#43.
To rotate the signer, run `setSubmitter(new, true)` and then `setSubmitter(old, false)` from the multisig.

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd adpriva-contracts

# Install Foundry dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with verbosity
forge test -vvv
```

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit with your configuration
vim .env
```

Required variables:
- `PRIVATE_KEY` - Your deployer private key (without 0x prefix)
- `HORIZEN_TESTNET_RPC_URL` - Horizen testnet RPC endpoint
- `HORIZEN_MAINNET_RPC_URL` - Horizen mainnet RPC endpoint (for production)

## Repository Structure

```
adpriva-contracts/
├── src/                          # Smart contracts source code
│   ├── Anchor.sol               # Production anchor contract (deployed, v1)
│   └── AnchorV2.sol             # Deduplicated, allowlisted v2 (merged, not deployed)
├── test/                        # Contract tests
│   ├── Anchor.t.sol            # Anchor contract tests
│   ├── AnchorV2.t.sol          # AnchorV2 tests (dedup, allowlist, pause, admin, fuzz, gas)
│   └── SmokeTests.t.sol        # Production smoke tests
├── script/                      # Deployment scripts
│   ├── Deploy*.s.sol           # Network-specific deployment scripts (DeployAnchorV2: v2)
│   └── VerifyDeployment.s.sol  # Post-deployment verification
├── docs/                        # Documentation
│   ├── anchor/                 # Anchor contract docs
│   └── deployment/             # Deployment guides
├── lib/                        # Foundry dependencies
├── foundry.toml               # Foundry configuration
├── .env.example               # Environment template
└── README.md                  # This file
```

## Usage

### Deploy Anchor Contract

```bash
# Deploy to Horizen testnet
forge script script/DeployHorizenTestnet.s.sol:DeployHorizenTestnet \
  --rpc-url horizen_testnet \
  --broadcast \
  -vvvv

# Verify deployment
forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url horizen_testnet
```

### Anchor a Proof Batch

```bash
cast send <ANCHOR_ADDRESS> \
  "anchor(bytes32,bytes32,string,string)" \
  <BATCH_ID_HASH> \
  <MERKLE_ROOT> \
  "horizen-testnet" \
  "My proof batch" \
  --rpc-url horizen_testnet \
  --private-key $PRIVATE_KEY
```

### Run Tests

```bash
# Run all tests
forge test

# Run specific test contract
forge test --match-contract AnchorTest

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage
```

## Security

### Anchor Contract (Production)

- **Status**: Security audited
- **Deployment**: Production-ready for Horizen mainnet
- **Risk Level**: Low (no funds at risk, immutable, event-only)
- **Audit**: Completed by professional security firm

See [docs/anchor/](docs/anchor/) for full security analysis.

## Supported Networks

### Production (Anchor Contract)
- **Horizen Mainnet** - Primary deployment target
- **Base Mainnet** - Alternative EVM network
- **Horizen Testnet** - Testing and development

## Documentation

- **[Deployment Guide](docs/deployment/DEPLOYMENT_GUIDE.md)** - How to deploy contracts
- **[Anchor ADRs](docs/anchor/)** - Architecture decision records
- **[Gas Optimization](docs/anchor/GAS_OPTIMIZATION.md)** - Gas usage analysis

## Development

### Running Local Node

```bash
# Start local Anvil node
anvil

# Deploy to local node (in another terminal)
forge script script/DeployLocal.s.sol:DeployLocal \
  --fork-url http://localhost:8545 \
  --broadcast
```

## Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_Anchor_SingleAnchor

# Generate coverage report
forge coverage

# Generate gas snapshot
forge snapshot
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

**Anchor Contract**: Production-ready and security audited. Suitable for mainnet deployment.

## Contributing

This is a public repository for transparency. For security vulnerabilities, please contact the development team directly rather than opening public issues.

## Support

For questions, issues, or deployment support:
- Review documentation in `docs/` directory
- Check ADRs for architectural decisions
- Run local tests to verify setup: `forge test`

---

**Built with Foundry and Solidity**
