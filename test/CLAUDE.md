# Tests

## Structure

```
test/
  VRFHandler.t.sol       # Base test contract with setup
  behaviours/            # Behavior-driven tests
    admin.t.sol
    constructor.t.sol
    fulfillRandomWords.t.sol
    requestRandomWords.t.sol
  mocks/                 # Test doubles
    MockVRFCoordinatorV2Plus.sol
    MockReceiver.sol
    VRFHandlerMock.sol
```

## Base Test (VRFHandler.t.sol)

Provides:
- Constants: KEY_HASH, SUBSCRIPTION_ID, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT
- Accounts: deployer, requester, randomUser
- Contract instances: coordinator, vrfHandler, receiver
- Helpers: `_generateRandomWords`, `_fulfillRandomWordsCall`

## Patterns

ALWAYS: Inherit from `VRFHandlerTest` base
ALWAYS: Use `makeAddr()` for test accounts
ALWAYS: Prefix helpers with `_`
ALWAYS: Test events with `vm.expectEmit`
ALWAYS: Test reverts with `vm.expectRevert`

## Mocks

- `MockVRFCoordinatorV2Plus` - Simulates Chainlink coordinator
- `MockReceiver` - Implements `IVRFHandlerReceiver`, tracks callbacks
- `VRFHandlerMock` - Exposes internal functions for testing

## Running

```bash
make test-fast                              # Quick run
make test-specific CONTRACT=VRFHandlerTest  # Single contract
make test-function FUNCTION=testRequest     # Single function
```
