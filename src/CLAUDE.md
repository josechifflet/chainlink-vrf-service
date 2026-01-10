# Source Contracts

## Files

- `VRFHandler.sol` - Core VRF intermediary contract
- `IVRFHandler.sol` - Request interface for consumers
- `IVRFHandlerReceiver.sol` - Callback interface for consumers

## VRFHandler

Inherits `VRFConsumerBaseV2Plus`. Manages:
- VRF configuration (subscription, keyHash, gas limits)
- Allowed requesters whitelist
- Request ID to requester/selector mapping
- Active request counter

### Key Functions

- `requestRandomWords(uint32)` - Default callback
- `requestRandomWords(uint32, bytes4)` - Custom callback selector
- `fulfillRandomWords(uint256, uint256[])` - Internal, called by coordinator
- Admin: `addAllowedRequester`, `setVrfConfig`, `setCallbackGasLimit`

## Patterns

CRITICAL: CEI pattern in `fulfillRandomWords` - state updates before `_callContract`
NEVER: Allow zero address or zero values in config
ALWAYS: Emit events for all state changes
ALWAYS: Use custom errors (Unauthorized, InvalidParameter, InvalidVrfState)

## Contract Structure

1. Types (VRFConfig struct)
2. State variables
3. Errors
4. Events
5. Constructor
6. External functions
7. Internal functions
8. Admin functions
