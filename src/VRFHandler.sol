// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

// VRF Handler Interface
import { IVRFHandler } from "./IVRFHandler.sol";
import { IVRFHandlerReceiver } from "./IVRFHandlerReceiver.sol";
// Chainlink
import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title VRFHandler - Version-agnostic intermediary for Chainlink VRF random number generation
/// @notice This contract decouples your main contracts from direct integration with Chainlink's VRF,
/// serving as an intermediary that handles random number requests. It allows your contracts to remain
/// unaffected by future VRF version changes (e.g., from VRF 2.0 to 2.5), as you can update or replace
/// the VRFHandler without modifying your main contract's logic. Contracts interact with this handler
/// via the IVRFHandlerReceiver interface, ensuring compatibility with future VRF upgrades.
contract VRFHandler is IVRFHandler, VRFConsumerBaseV2Plus {
  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Types
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @dev Configuration parameters for Chainlink VRF requests
  struct VRFConfig {
    uint256 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    bool nativePaymentEnabled;
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ State variables
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @dev VRF configuration parameters
  VRFConfig internal vrfConfig;

  /// @dev Contract Address => Bool indicating if the contract is allowed to request random numbers
  mapping(address requester => bool isAllowed) public allowedRequesters;

  /// @dev VRF Request ID => Contract that requested the random numbers
  mapping(uint256 requestId => address requester) public vrfRequestIdToRequester;

  /// @dev VRF Fulfilled Request => Bool indicating if the request has been fulfilled
  mapping(uint256 requestId => bool isFulfilled) public vrfFulfilledRequests;

  /// @dev VRF Request ID => Selector of the callback function
  mapping(uint256 requestId => bytes4 selector) public vrfRequestIdToSelector;

  /// @dev Counter of outstanding requests
  uint256 public activeRequests;

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Errors
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @dev Emitted when an unauthorized address requests random numbers
  error Unauthorized();

  /// @dev Emitted when the VRF is in an invalid state
  error InvalidVrfState();

  /// @dev Emitted when a parameter provided is invalid
  error InvalidParameter();

  /// @dev Emitted when an external call fails
  error ExternalCallFailed();

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Events
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @dev Emitted when an address is added to the allowed requesters
  event AllowedRequesterAdded(address indexed requester);

  /// @dev Emitted when an address is removed from the allowed requesters
  event AllowedRequesterRemoved(address indexed requester);

  /// @dev Emitted when the request confirmations are set
  event RequestConfirmationsSet(uint16 requestConfirmations);

  /// @dev Emitted when the callback gas limit is set
  event CallbackGasLimitSet(uint32 callbackGasLimit);

  /// @dev Emitted when a random words request is made
  event RandomWordsRequested(uint256 indexed requestId, address indexed requester, uint32 randomWordsAmount);

  /// @dev Emitted when a random words request is fulfilled
  event RandomWordsFulfilled(uint256 indexed requestId, address indexed requester, uint256[] randomWords);

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Constructor
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Initializes the VRFHandler with Chainlink VRF configuration
  /// @param _coordinator The address of the VRF Coordinator
  /// @param _keyHash The key hash for VRF requests
  /// @param _subscriptionId The Chainlink VRF subscription ID
  /// @param _requestConfirmations The number of confirmations to wait before fulfilling a request
  /// @param _callbackGasLimit The gas limit for the callback function
  /// @param _nativePaymentEnabled If true, the contract will use native gas for VRF requests
  constructor(
    address _coordinator,
    bytes32 _keyHash,
    uint256 _subscriptionId,
    uint16 _requestConfirmations,
    uint32 _callbackGasLimit,
    bool _nativePaymentEnabled
  )
    VRFConsumerBaseV2Plus(_coordinator)
  {
    // Input validation
    if (_coordinator == address(0)) revert InvalidParameter();
    if (_keyHash == bytes32(0)) revert InvalidParameter();
    if (_subscriptionId == 0) revert InvalidParameter();
    if (_callbackGasLimit == 0) revert InvalidParameter();

    // Initialize VRF configuration
    vrfConfig = VRFConfig({
      keyHash: _keyHash,
      subscriptionId: _subscriptionId,
      requestConfirmations: _requestConfirmations,
      callbackGasLimit: _callbackGasLimit,
      nativePaymentEnabled: _nativePaymentEnabled
    });
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ External functions
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Request random words with the default callback function (`fulfillRandomWords`)
  /// @dev Requests random numbers from Chainlink VRF and uses the standard callback
  /// @param randomWordsAmount The number of random words to request
  /// @return requestId The unique identifier for this request
  function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId) {
    // Ensure the caller is authorized
    if (!allowedRequesters[msg.sender]) revert Unauthorized();
    if (randomWordsAmount == 0) revert InvalidParameter();

    // Increment the counter of active requests
    unchecked {
      activeRequests++;
    }

    // Create the VRF request
    requestId = _createVRFRequest(randomWordsAmount);

    // Store the default selector of the callback function
    vrfRequestIdToSelector[requestId] = IVRFHandlerReceiver.fulfillRandomWords.selector;

    // Store the requester address for this request ID
    vrfRequestIdToRequester[requestId] = msg.sender;

    // Emit the event
    emit RandomWordsRequested(requestId, msg.sender, randomWordsAmount);
  }

  /// @notice Request random words with a custom selector as the callback function
  /// @dev Allows specifying a custom function selector for the callback
  /// @param randomWordsAmount The number of random words to request
  /// @param selector The selector of the callback function
  /// @return requestId The unique identifier for this request
  function requestRandomWords(uint32 randomWordsAmount, bytes4 selector) external returns (uint256 requestId) {
    // Ensure the caller is authorized
    if (!allowedRequesters[msg.sender]) revert Unauthorized();
    if (randomWordsAmount == 0) revert InvalidParameter();
    if (selector == bytes4(0)) revert InvalidParameter();

    // Increment the counter of active requests
    unchecked {
      activeRequests++;
    }

    // Create the VRF request
    requestId = _createVRFRequest(randomWordsAmount);

    // Store the selector of the callback function provided by the caller
    vrfRequestIdToSelector[requestId] = selector;

    // Store the requester address for this request ID
    vrfRequestIdToRequester[requestId] = msg.sender;

    // Emit the event
    emit RandomWordsRequested(requestId, msg.sender, randomWordsAmount);
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Internal functions
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @dev Creates a request to the VRF coordinator for random words
  /// @param randomWordsAmount The number of random words to request
  /// @return requestId The unique identifier for this request
  function _createVRFRequest(uint32 randomWordsAmount) internal returns (uint256 requestId) {
    // Request random words from Chainlink's VRF coordinator
    requestId = s_vrfCoordinator.requestRandomWords(
      VRFV2PlusClient.RandomWordsRequest({
        requestConfirmations: vrfConfig.requestConfirmations,
        callbackGasLimit: vrfConfig.callbackGasLimit,
        keyHash: vrfConfig.keyHash,
        subId: vrfConfig.subscriptionId,
        numWords: randomWordsAmount,
        extraArgs: VRFV2PlusClient._argsToBytes(
          VRFV2PlusClient.ExtraArgsV1({ nativePayment: vrfConfig.nativePaymentEnabled })
        )
      })
    );
  }

  /// @dev Callback function called by Chainlink's VRF coordinator when random words are ready
  /// @param _requestId The request ID
  /// @param _randomWords The random numbers
  function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
    // Verify the request hasn't been fulfilled and is valid
    if (vrfFulfilledRequests[_requestId]) revert InvalidVrfState();

    // Get the requester address
    address requester = vrfRequestIdToRequester[_requestId];
    if (requester == address(0)) revert Unauthorized();

    // Update state before external calls

    // Mark the request as fulfilled
    vrfFulfilledRequests[_requestId] = true;

    // Clean up the request data
    delete vrfRequestIdToRequester[_requestId];

    // Decrement active requests counter
    unchecked {
      activeRequests--;
    }

    // Emit the fulfillment event
    emit RandomWordsFulfilled(_requestId, requester, _randomWords);

    // Make external call after state changes

    // Prepare the callback data with the correct selector and parameters
    bytes memory callData = abi.encodeWithSelector(vrfRequestIdToSelector[_requestId], _requestId, _randomWords);

    // Clean up the selector after use
    delete vrfRequestIdToSelector[_requestId];

    // Use `_callContract` to make a safer external call with proper error handling
    _callContract(requester, callData);
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Admin functions
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Add an address to the allowed requesters
  /// @param _requester The address to authorize for random number requests
  function addAllowedRequester(address _requester) external onlyOwner {
    if (_requester == address(0)) revert InvalidParameter();
    allowedRequesters[_requester] = true;
    emit AllowedRequesterAdded(_requester);
  }

  /// @notice Remove an address from the allowed requesters
  /// @param _requester The address to remove authorization from
  function removeAllowedRequester(address _requester) external onlyOwner {
    if (_requester == address(0)) revert InvalidParameter();
    allowedRequesters[_requester] = false;
    emit AllowedRequesterRemoved(_requester);
  }

  /// @notice Set the request confirmations
  /// @param _requestConfirmations The number of confirmations to wait
  function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
    vrfConfig.requestConfirmations = _requestConfirmations;
    emit RequestConfirmationsSet(_requestConfirmations);
  }

  /// @notice Set the callback gas limit
  /// @param _callbackGasLimit The gas limit for callbacks
  function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
    if (_callbackGasLimit == 0) revert InvalidParameter();
    vrfConfig.callbackGasLimit = _callbackGasLimit;
    emit CallbackGasLimitSet(_callbackGasLimit);
  }

  /// @notice Makes a call to `target`, with `data`.
  /// @dev author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibCall.sol)
  /// @dev author Modified from ExcessivelySafeCall (https://github.com/nomad-xyz/ExcessivelySafeCall)
  /// @dev Makes a call to `target`, with `data`.
  function _callContract(address target, bytes memory data) internal returns (bytes memory result) {
    /// @solidity memory-safe-assembly
    assembly {
      result := mload(0x40)
      if iszero(call(gas(), target, 0, add(data, 0x20), mload(data), codesize(), 0x00)) {
        // Bubble up the revert if the call reverts.
        returndatacopy(result, 0x00, returndatasize())
        revert(result, returndatasize())
      }
      if iszero(returndatasize()) {
        if iszero(extcodesize(target)) {
          mstore(0x00, 0x5a836a5f) // `TargetIsNotContract()`.
          revert(0x1c, 0x04)
        }
      }
      mstore(result, returndatasize()) // Store the length.
      let o := add(result, 0x20)
      returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
      mstore(0x40, add(o, returndatasize())) // Allocate the memory.
    }
  }
}
