// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// VRF Handler Interface
import { IVRFHandler } from "./IVRFHandler.sol";
import { IVRFHandlerReceiver } from "./IVRFHandlerReceiver.sol";
// Chainlink
import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { IVRFCoordinatorV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// Custom Revert
import { CustomRevert } from "./CustomRevert.sol";

/// @title VRFHandler - Version-agnostic intermediary for Chainlink VRF random number generation
/// @notice This contract decouples your main contracts from direct integration with Chainlink's VRF,
/// serving as an intermediary that handles random number requests. It allows your contracts to remain
/// unaffected by future VRF version changes (e.g., from VRF 2.0 to 2.5), as you can update or replace
/// the VRFHandler without modifying your main contract's logic. Contracts interact with this handler
/// via the IVRFHandlerReceiver interface, ensuring compatibility with future VRF upgrades.
contract VRFHandler is IVRFHandler, VRFConsumerBaseV2Plus {
  using CustomRevert for bytes4;

  /// @notice - Chainlink VRF
  uint16 internal requestConfirmations;
  uint32 internal callbackGasLimit;
  uint256 internal subscriptionId;
  bytes32 internal keyHash;
  bool internal nativePaymentEnabled;

  // Contract Address => Bool indicating if the contract is allowed to request random numbers
  mapping(address requester => bool isAllowed) public allowedRequesters;

  // VRF Request ID => Contract that requested the random numbers
  mapping(uint256 requestId => address requester) public vrfRequestIdToRequester;

  // VRF Fulfilled Request => Bool indicating if the request has been fulfilled
  mapping(uint256 requestId => bool isFulfilled) public vrfFulfilledRequests;

  // Counter of outstanding requests
  uint256 public activeRequests;

  /// @notice Errors
  /// @dev - Emitted when an unauthorized address requests random numbers
  error Unauthorized();
  /// @dev - Emitted when the VRF is in an invalid state
  error InvalidVrfState();

  /// @notice Events
  /// @dev - Emitted when an address is added to the allowed requesters
  event AllowedRequesterAdded(address requester);
  /// @dev - Emitted when an address is removed from the allowed requesters
  event AllowedRequesterRemoved(address requester);
  /// @dev - Emitted when the request confirmations are set
  event RequestConfirmationsSet(uint16 requestConfirmations);
  /// @dev - Emitted when the callback gas limit is set
  event CallbackGasLimitSet(uint32 callbackGasLimit);
  /// @dev - Emitted when a random words request is made
  event RandomWordsRequested(uint256 requestId, address requester, uint32 randomWordsAmount);
  /// @dev - Emitted when a random words request is fulfilled
  event RandomWordsFulfilled(uint256 requestId, address requester, uint256[] randomWords);

  /// @notice Constructor
  /// @dev - OtcBox is OwnableBasic, which inherits OpenZeppelin's OwnablePermissions and Ownable. Making the deployer
  /// of the contract as the initial owner.
  ///
  /// @param _coordinator - The address of the VRF Coordinator
  /// @param _keyHash - The key hash
  /// @param _subscriptionId - The subscription ID
  /// @param _requestConfirmations - The request confirmations
  /// @param _callbackGasLimit - The callback gas limit
  /// @param _nativePaymentEnabled - If true, the contract will use native gas for the VRF requests
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
    keyHash = _keyHash;
    subscriptionId = _subscriptionId;
    requestConfirmations = _requestConfirmations;
    callbackGasLimit = _callbackGasLimit;
    nativePaymentEnabled = _nativePaymentEnabled;
  }

  /// [Chainlink] Request a random number to Chainlink's VRF
  /// @param randomWordsAmount - The amount of random numbers to request
  function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId) {
    // [Safety Check] Revert if the caller is not allowed to request random numbers
    if (!allowedRequesters[msg.sender]) Unauthorized.selector.revertWith();

    // Increment the counter of active requests
    unchecked {
      activeRequests++;
    }

    // Request random words to Chainlink's VRF service
    requestId = s_vrfCoordinator.requestRandomWords(
      VRFV2PlusClient.RandomWordsRequest({
        requestConfirmations: requestConfirmations,
        callbackGasLimit: callbackGasLimit,
        keyHash: keyHash,
        subId: subscriptionId,
        numWords: randomWordsAmount,
        extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: nativePaymentEnabled }))
      })
    );

    // Store the contract that requested the random numbers
    vrfRequestIdToRequester[requestId] = msg.sender;

    // Emit the RandomWordsRequested event
    emit RandomWordsRequested(requestId, msg.sender, randomWordsAmount);
  }

  // [Chainlink] Callback function called by Chainlink's VRF
  /// @param _requestId - The request ID
  /// @param _randomWords - The random numbers
  function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
    // Check if the request has already been fulfilled
    if (vrfFulfilledRequests[_requestId]) InvalidVrfState.selector.revertWith();

    // Cache the contract that requested the random numbers based on the request ID
    address contractRequestor = vrfRequestIdToRequester[_requestId];

    // Revert if the contract that requested the random numbers is not found
    if (contractRequestor == address(0)) Unauthorized.selector.revertWith();

    // Delete the active requestId -> requestor record
    delete vrfRequestIdToRequester[_requestId];

    // Mark the request as fulfilled
    vrfFulfilledRequests[_requestId] = true;

    // Decrement the counter of outstanding requests
    unchecked {
      activeRequests--;
    }

    // Emit the RandomWordsFulfilled event
    emit RandomWordsFulfilled(_requestId, contractRequestor, _randomWords);

    // Call the contract that requested the random numbers with the random numbers
    IVRFHandlerReceiver(contractRequestor).fulfillRandomWords(_requestId, _randomWords);
  }

  /*//////////////////////////////////////////////////////////////
                ONLY OWNER
  //////////////////////////////////////////////////////////////*/

  /// @notice - Add an address to the allowed requesters
  /// @param _requester - The address to add
  function addAllowedRequester(address _requester) external onlyOwner {
    allowedRequesters[_requester] = true;

    emit AllowedRequesterAdded(_requester);
  }

  /// @notice - Remove an address from the allowed requesters
  /// @param _requester - The address to remove
  function removeAllowedRequester(address _requester) external onlyOwner {
    allowedRequesters[_requester] = false;

    emit AllowedRequesterRemoved(_requester);
  }

  /// @notice - Set the request confirmations
  /// @param _requestConfirmations - The request confirmations
  function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
    requestConfirmations = _requestConfirmations;

    emit RequestConfirmationsSet(_requestConfirmations);
  }

  /// @notice - Set the callback gas limit
  /// @param _callbackGasLimit - The callback gas limit
  function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
    callbackGasLimit = _callbackGasLimit;

    emit CallbackGasLimitSet(_callbackGasLimit);
  }
}
