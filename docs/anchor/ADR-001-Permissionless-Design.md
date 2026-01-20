# ADR-001: Permissionless Contract Design

**Status:** Accepted  
**Date:** 2026-01-07  
**Decision Makers:** AdPriva Engineering Team  

## Context

The Anchor.sol contract needs to store proof batch commitments (Merkle roots) on the blockchain for public verification. We must decide whether to implement access control (restrict who can call `anchor()`) or allow permissionless anchoring.

## Decision

We will implement a **permissionless design** where anyone can call the `anchor()` and `anchorBatch()` functions without access control.

## Rationale

### Why Permissionless?

1. **Simplicity & Security**
   - No complex access control logic = smaller attack surface
   - No need for owner key management or multi-sig complexity
   - Eliminates risk of access control bugs or centralization concerns

2. **Backend Filtering Strategy**
   - AdPriva backend only monitors events from the authorized submitter address
   - Unauthorized anchors are simply ignored by the backend
   - No on-chain cost for preventing spam (spam pays its own gas)

3. **Public Verifiability**
   - Anyone can verify proof inclusion against anchored Merkle roots
   - No gatekeeping for verification queries
   - Aligns with transparency principles

4. **Gas Efficiency**
   - No access control checks = lower gas costs per anchor
   - Critical for high-volume anchoring operations

5. **Immutability**
   - Events are append-only and immutable
   - Spam/unauthorized anchors don't affect valid data integrity
   - No ability to delete or modify existing anchors

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Spam Anchors** | Noise in event logs | Backend filters by submitter address; spam pays own gas |
| **Confusion** | Users may anchor to wrong address | Clear documentation; backend ignores unauthorized events |
| **Event Log Bloat** | Increased indexing costs | Minimal impact; indexers handle high volume efficiently |

### Considered Alternatives

#### Alternative 1: Ownable Pattern
```solidity
contract Anchor is Ownable {
    function anchor(...) external onlyOwner {
        // ...
    }
}
```

**Rejected because:**
- Adds centralization risk (owner key compromise)
- Higher gas costs (access control checks)
- Requires key management infrastructure
- No significant benefit over backend filtering

#### Alternative 2: Allowlist Pattern
```solidity
mapping(address => bool) public allowedSubmitters;

function anchor(...) external {
    require(allowedSubmitters[msg.sender], "Not authorized");
    // ...
}
```

**Rejected because:**
- Requires on-chain allowlist management
- Gas costs for storage reads
- Inflexible (need transactions to update list)
- Backend filtering achieves same result off-chain

#### Alternative 3: Pausable Emergency Stop
```solidity
contract Anchor is Pausable {
    function anchor(...) external whenNotPaused {
        // ...
    }
}
```

**Partially considered:** Could add pausability for emergencies, but:
- Contract is immutable by design (see ADR-002)
- If vulnerability found, deploy new version instead
- Pause mechanism adds complexity without clear benefit

## Consequences

### Positive
- ✅ Simple, auditable code
- ✅ Lower gas costs
- ✅ No centralization concerns
- ✅ Easy to verify and reason about
- ✅ Backend has full control via filtering

### Negative
- ⚠️ Event logs may contain spam anchors
- ⚠️ Users might accidentally anchor to contract
- ⚠️ No on-chain protection against abuse

### Neutral
- Backend must implement robust event filtering
- Documentation must clearly explain permissionless design
- Monitoring should track spam/unusual activity

## Implementation Notes

1. **Backend Event Filtering**
   ```javascript
   // Filter events by authorized submitter only
   const authorizedEvents = events.filter(
     event => event.submitter === AUTHORIZED_ADDRESS
   );
   ```

2. **Documentation Requirements**
   - Contract comments explain permissionless design
   - Integration guide shows proper event filtering
   - User guide warns against anchoring to wrong contract

3. **Monitoring**
   - Alert on unusually high anchor rate from unknown addresses
   - Track gas costs for spam detection
   - Log unauthorized anchors for analysis

## Review & Updates

This decision should be reviewed if:
- Spam becomes a significant operational problem
- Regulatory requirements mandate access control
- Event indexing costs become prohibitive
- Security audit recommends changes

## References

- Anchor.sol contract comments (lines 8-10)
- Backend event filtering implementation
- Gas cost analysis (test/Anchor.t.sol)

