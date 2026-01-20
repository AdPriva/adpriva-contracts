# Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying contracts to Horizen blockchain networks.

## Prerequisites

### Required Tools
- Foundry (forge, cast, anvil)
- Git
- Access to deployment wallet private key
- RPC endpoint for Horizen testnet/mainnet

### Required Credentials
- Deployer private key with sufficient native tokens
- Block explorer API key (if verification is supported)

### Pre-Deployment Checklist

- [ ] All tests passing (`forge test`)
- [ ] Security audit completed (for production deployments)
- [ ] Gas benchmarks reviewed
- [ ] Deployment scripts tested on testnet
- [ ] Monitoring infrastructure ready (optional)
- [ ] Team notified of deployment window
- [ ] Rollback plan prepared

## Deployment Steps

### 1. Environment Setup

Create `.env` file (never commit this!):

```bash
# Copy from example
cp .env.example .env

# Edit with your values
vim .env
```

Required variables:
```bash
# Deployment
PRIVATE_KEY=your_private_key_without_0x_prefix
HORIZEN_TESTNET_RPC_URL=https://horizen-testnet.rpc.caldera.xyz/http
HORIZEN_MAINNET_RPC_URL=https://horizen-mainnet.rpc.endpoint/http

# Optional: Block explorer API key
BASESCAN_API_KEY=your_api_key
```

### 2. Verify Deployer Account

Check deployer address and balance:

```bash
# Get deployer address
cast wallet address --private-key $PRIVATE_KEY

# Check balance on Horizen testnet
cast balance <DEPLOYER_ADDRESS> --rpc-url $HORIZEN_TESTNET_RPC_URL

# Ensure you have sufficient balance for deployment + gas
```

### 3. Deploy to Horizen Testnet

**Always deploy to testnet first!**

#### Deploy Anchor Contract

```bash
forge script script/DeployHorizenTestnet.s.sol:DeployHorizenTestnet \
  --rpc-url horizen_testnet \
  --broadcast \
  -vvvv
```

Expected output:
```
================================================
Deploying Anchor Contract to Horizen Testnet
================================================
Deployer: 0x...
Chain ID: [chain_id]
Anchor contract deployed to: 0x...
  --broadcast
```

### 4. Verify Deployment

```bash
# Run smoke tests
forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url horizen_testnet \
  -vvvv

# Test a single anchor
cast send <ANCHOR_ADDRESS> \
  "anchor(bytes32,bytes32,string,string)" \
  0x1234567890123456789012345678901234567890123456789012345678901234 \
  0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd \
  "horizen-testnet" \
  "Test anchor" \
  --rpc-url horizen_testnet \
  --private-key $PRIVATE_KEY
```

### 5. Update Environment Variables

After successful deployment, update `.env` with deployed addresses:

```bash
ANCHOR_HORIZEN_TESTNET_ADDRESS=0x...
ZKMIXER_HORIZEN_TESTNET_ADDRESS=0x...
```

## Production Deployment (Horizen Mainnet)

### Pre-Production Checklist

- [ ] Testnet deployment successful and tested
- [ ] Security audit completed and issues resolved
- [ ] All stakeholders notified
- [ ] Monitoring and alerting configured
- [ ] Incident response plan in place
- [ ] Sufficient native tokens in deployer wallet

### Deploy to Mainnet

```bash
# Deploy Anchor
forge script script/DeployBase.s.sol:DeployBase \
  --rpc-url horizen_mainnet \
  --broadcast \
  --verify \
  -vvvv

# IMPORTANT: Verify the contract on block explorer
# IMPORTANT: Test with a small transaction first
# IMPORTANT: Monitor contract events immediately after deployment
```

### Post-Deployment

1. **Verify contract source code** on block explorer
2. **Run smoke tests** against deployed contract
3. **Monitor first transactions** closely
4. **Update documentation** with contract addresses
5. **Notify backend team** to update integration endpoints
6. **Archive deployment artifacts** for audit trail

## Troubleshooting

### Insufficient Balance
```bash
# Check balance
cast balance <ADDRESS> --rpc-url horizen_testnet

# Request testnet tokens from faucet
# For mainnet: ensure sufficient balance before deploying
```

### RPC Connection Issues
```bash
# Test RPC connection
cast block-number --rpc-url $HORIZEN_TESTNET_RPC_URL

# Try alternative RPC endpoint if available
```

### Gas Estimation Failures
```bash
# Increase gas limit in forge script
forge script ... --gas-limit 5000000

# Or specify gas price
forge script ... --gas-price 1000000000
```

## Security Best Practices

1. **Never commit `.env` file** - Add to `.gitignore`
2. **Use hardware wallets** for mainnet deployments when possible
3. **Test thoroughly** on testnet before mainnet
4. **Verify contract source** on block explorer
5. **Use multi-sig wallets** for contract ownership (if applicable)
6. **Monitor contract events** immediately after deployment
7. **Have incident response plan** ready

## Support

For deployment issues or questions:
- Check documentation in `docs/` directory
- Review ADRs for architectural decisions
- Run tests locally to verify setup: `forge test`
