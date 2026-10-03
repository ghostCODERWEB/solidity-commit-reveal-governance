# ABI reference

Generated from the successfully compiled primary contract. Includes inherited OpenZeppelin methods. Authorization requirements and economic semantics are in the Solidity source and architecture guide.

| Signature | Type | Mutability | Return values |
|---|---|---|---|
| `constructor(address asset,address admin)` | constructor | nonpayable |  |
| `EnforcedPause()` | error |  |  |
| `ExpectedPause()` | error |  |  |
| `OwnableInvalidOwner(address owner)` | error |  |  |
| `OwnableUnauthorizedAccount(address account)` | error |  |  |
| `ReentrancyGuardReentrantCall()` | error |  |  |
| `SafeERC20FailedOperation(address token)` | error |  |  |
| `Committed(uint256 id,address voter,uint256 weight)` | event |  |  |
| `Finalized(uint256 id,bool passed)` | event |  |  |
| `OwnershipTransferStarted(address previousOwner,address newOwner)` | event |  |  |
| `OwnershipTransferred(address previousOwner,address newOwner)` | event |  |  |
| `Paused(address account)` | event |  |  |
| `Proposed(uint256 id,uint64 commitEnd,uint64 revealEnd,uint256 quorum)` | event |  |  |
| `Revealed(uint256 id,address voter,bool support,uint256 weight)` | event |  |  |
| `Unpaused(address account)` | event |  |  |
| `acceptOwnership()` | function | nonpayable |  |
| `ballotHash(uint256 id,address voter,bool support,bytes32 salt)` | function | view | bytes32  |
| `ballots(uint256 ,address )` | function | view | bytes32 commitment, uint256 weight, bool revealed, bool withdrawn |
| `commit(uint256 id,bytes32 hash,uint256 weight)` | function | nonpayable |  |
| `escrowed()` | function | view | uint256  |
| `finalize(uint256 id)` | function | nonpayable |  |
| `nextProposal()` | function | view | uint256  |
| `owner()` | function | view | address  |
| `paused()` | function | view | bool  |
| `pendingOwner()` | function | view | address  |
| `proposals(uint256 )` | function | view | uint64 commitEnd, uint64 revealEnd, uint256 quorum, uint256 yes, uint256 no, bool finalized, bool passed |
| `propose(uint64 commitDuration,uint64 revealDuration,uint256 quorum)` | function | nonpayable | uint256 id |
| `renounceOwnership()` | function | nonpayable |  |
| `reveal(uint256 id,bool support,bytes32 salt)` | function | nonpayable |  |
| `setPaused(bool value)` | function | nonpayable |  |
| `token()` | function | view | address  |
| `transferOwnership(address newOwner)` | function | nonpayable |  |
| `withdraw(uint256 id)` | function | nonpayable |  |
