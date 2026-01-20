# ADR-002: Immutable Contract Architecture

**Status:** Accepted  
**Date:** 2026-01-07  
**Decision Makers:** AdPriva Engineering Team  

## Context

Smart contracts can be deployed as either:
1. **Immutable** - Cannot be modified after deployment
2. **Upgradeable** - Can be modified using proxy patterns (UUPS, Transparent, etc.)

We must decide the upgrade strategy for the Anchor.sol contract.

## Decision

We will deploy Anchor.sol as an **immutable contract** without upgradeability mechanisms.

## Rationale

### Why Immutable?

1. **Simplicity & Security**
   - No proxy complexity = smaller attack surface
   - No risk of proxy vulnerabilities (storage collisions, delegation bugs)
   - Easier to audit and verify
   - No admin key management required

2. **Contract Functionality**
   - Contract has a single, well-defined purpose: emit events
   - No storage state that needs migration
   - No complex logic that might need fixes
   - Events are immutable by nature

3. **Trust & Transparency**
   - Users can trust the contract won't change behavior
   - No risk of malicious upgrades
   - Full transparency about contract capabilities
   - Aligns with decentralization principles

4. **Gas Efficiency**
   - Direct calls (no proxy delegation overhead)
   - Lower deployment costs
   - Simpler deployment process

### Handling Future Changes

If changes are needed (bug fixes, feature additions), we will:

1. **Deploy new contract version**
   ```
   Anchor v1.0 → 0xAAA... (current production)
   Anchor v1.1 → 0xBBB... (new version with fixes)
   ```

2. **Migrate backend gradually**
   ```
   Backend reads from both v1.0 and v1.1 during transition
   Backend switches anchoring to v1.1
   Backend stops monitoring v1.0 after migration period
   ```

3. **Preserve historical data**
   - Old contract events remain accessible
   - Backend indexes both contracts
   - Documentation tracks all deployed versions

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Bug Discovery** | Cannot fix deployed contract | Thorough testing, audits, gradual rollout; deploy new version if needed |
| **Feature Needs** | Cannot add features | Design for extensibility; deploy new versions as needed |
| **Migration Complexity** | Backend must support multiple contracts | Design backend for multi-contract support from day 1 |

### Considered Alternatives

#### Alternative 1: UUPS Proxy Pattern
```solidity
contract Anchor is UUPSUpgradeable {
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {}
    // ... rest of contract
}
```

**Rejected because:**
- Adds significant complexity for minimal benefit
- Introduces proxy security risks
- Requires admin key management
- Gas overhead on every call
- Not needed for simple event emission contract

#### Alternative 2: Transparent Proxy Pattern
```solidity
// Separate proxy and implementation contracts
ProxyAdmin → Proxy → Implementation
```

**Rejected because:**
- Even more complex than UUPS
- Higher gas costs
- Overkill for this use case
- Same downsides as UUPS

#### Alternative 3: Diamond Pattern (EIP-2535)
```solidity
// Multiple facets, complex upgrade logic
Diamond → [Facet1, Facet2, Facet3, ...]
```

**Rejected because:**
- Extremely complex
- Not suitable for simple contracts
- Higher gas and deployment costs
- Unnecessary for event emission

## Consequences

### Positive
- ✅ Maximum simplicity and security
- ✅ Lower gas costs
- ✅ Easier to audit
- ✅ No admin key risks
- ✅ True decentralization

### Negative
- ⚠️ Cannot fix bugs in deployed contract
- ⚠️ Cannot add features without new deployment
- ⚠️ Backend must support multi-contract indexing

### Neutral
- Backend needs version management strategy
- Documentation must track deployed versions
- Testing becomes even more critical

## Implementation Strategy

### Version Management

```
contracts/
  ├── Anchor.sol              # Current version
  └── archive/
      └── Anchor_v1.0.0.sol   # Historical versions

deployments/
  ├── mainnet.json
  │   {
  │     "v1.0.0": "0xAAA...",
  │     "v1.1.0": "0xBBB...",
  │     "current": "0xBBB..."
  │   }
  └── testnet.json
```

### Deployment Process

1. **Thorough Testing**
   - Comprehensive test suite (✅ implemented)
   - Fuzz testing (✅ implemented)
   - Gas benchmarks (✅ implemented)
   - Integration tests (✅ implemented)

2. **Security Review**
   - Static analysis with Slither
   - Professional audit (recommended)
   - Internal code review
   - Public review period

3. **Staged Rollout**
   - Deploy to testnet first
   - Run for 1-2 weeks with backend integration
   - Deploy to mainnet
   - Monitor closely for 1 week
   - Gradually increase usage

4. **Emergency Plan**
   - If critical bug found: deploy new version immediately
   - Backend switches to new version
   - Publish incident report
   - Update documentation

### Backend Integration

Backend must support multiple contract versions:

```javascript
const ANCHOR_CONTRACTS = {
  current: "0xBBB...",
  v1_0_0: "0xAAA...",
  v1_1_0: "0xBBB..."
};

// Monitor all versions for historical data
const allEvents = await Promise.all(
  Object.values(ANCHOR_CONTRACTS).map(addr => 
    queryEvents(addr, filters)
  )
);

// Anchor to current version only
await anchorToContract(ANCHOR_CONTRACTS.current, data);
```

## Testing Requirements

Given immutability, testing is critical:

- ✅ Unit tests for all functions
- ✅ Event emission verification
- ✅ Fuzz testing
- ✅ Gas benchmarks
- ✅ Integration tests
- ✅ Edge case coverage
- ✅ Security scanning (Slither)
- ⏳ Professional audit (recommended)

## Documentation Requirements

- Contract version in comments
- Deployment addresses tracked
- Migration guides for version changes
- Backend integration guide
- Incident response procedures

## Review & Updates

This decision should be reviewed if:
- Critical bugs are discovered frequently
- Upgrade needs become common
- Regulatory requirements change
- User demand for upgradeability increases

## References

- OpenZeppelin documentation on upgradeability
- Trail of Bits: Building Secure Contracts
- Anchor.sol implementation
- Backend integration architecture

