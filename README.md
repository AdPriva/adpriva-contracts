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
│   └── Anchor.sol               # Production anchor contract
├── test/                        # Contract tests
│   ├── Anchor.t.sol            # Anchor contract tests
│   └── SmokeTests.t.sol        # Production smoke tests
├── script/                      # Deployment scripts
│   ├── Deploy*.s.sol           # Network-specific deployment scripts
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
