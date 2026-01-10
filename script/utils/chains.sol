// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

/// @title ChainConfig
/// @notice Provides chain-specific configuration for VRF deployment
library ChainConfig {
  // Ethereum
  address internal constant COORDINATOR_ETHEREUM_MAINNET = 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a;
  address internal constant COORDINATOR_ETHEREUM_SEPOLIA = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
  bytes32 internal constant KEY_HASH_ETHEREUM_MAINNET_500GWEI =
    0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b;
  bytes32 internal constant KEY_HASH_ETHEREUM_SEPOLIA_500GWEI =
    0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

  // Arbitrum
  address internal constant COORDINATOR_ARBITRUM_MAINNET = 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e;
  address internal constant COORDINATOR_ARBITRUM_SEPOLIA = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;
  bytes32 internal constant KEY_HASH_ARBITRUM_MAINNET_150GWEI =
    0xe9f223d7d83ec85c4f78042a4845af3a1c8df7757b4997b815ce4b8d07aca68c;
  bytes32 internal constant KEY_HASH_ARBITRUM_SEPOLIA_50GWEI =
    0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;

  // Base
  address internal constant COORDINATOR_BASE_MAINNET = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
  address internal constant COORDINATOR_BASE_SEPOLIA = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE;
  bytes32 internal constant KEY_HASH_BASE_MAINNET_30GWEI =
    0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70;
  bytes32 internal constant KEY_HASH_BASE_SEPOLIA_30GWEI =
    0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71;

  // Polygon
  address internal constant COORDINATOR_POLYGON_MAINNET = 0xec0Ed46f36576541C75739E915ADbCb3DE24bD77;
  address internal constant COORDINATOR_POLYGON_AMOY = 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2;
  bytes32 internal constant KEY_HASH_POLYGON_MAINNET_500GWEI =
    0x719ed7d7664abc3001c18aac8130a2265e1e70b7e036ae20f3ca8b92b3154d86;
  bytes32 internal constant KEY_HASH_POLYGON_AMOY_500GWEI =
    0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899;

  /// @notice Gets the VRF coordinator address for the given chain ID
  /// @param chainId The chain ID
  /// @return The VRF coordinator address for the chain
  function getCoordinator(uint256 chainId) internal pure returns (address) {
    // Ethereum
    if (chainId == 1) return COORDINATOR_ETHEREUM_MAINNET;
    if (chainId == 11_155_111) return COORDINATOR_ETHEREUM_SEPOLIA;

    // Arbitrum
    if (chainId == 42_161) return COORDINATOR_ARBITRUM_MAINNET;
    if (chainId == 421_614) return COORDINATOR_ARBITRUM_SEPOLIA;

    // Base
    if (chainId == 8453) return COORDINATOR_BASE_MAINNET;
    if (chainId == 84_532) return COORDINATOR_BASE_SEPOLIA;

    // Polygon
    if (chainId == 137) return COORDINATOR_POLYGON_MAINNET;
    if (chainId == 80_002) return COORDINATOR_POLYGON_AMOY;

    revert("Unsupported chain ID");
  }

  /// @notice Gets the default key hash for the given chain ID
  /// @param chainId The chain ID
  /// @return The default key hash for the chain
  function getDefaultKeyHash(uint256 chainId) internal pure returns (bytes32) {
    // Ethereum
    if (chainId == 1) return KEY_HASH_ETHEREUM_MAINNET_500GWEI;
    if (chainId == 11_155_111) return KEY_HASH_ETHEREUM_SEPOLIA_500GWEI;

    // Arbitrum - using the middle option (30 gwei) for mainnet
    if (chainId == 42_161) return KEY_HASH_ARBITRUM_MAINNET_150GWEI;
    if (chainId == 421_614) return KEY_HASH_ARBITRUM_SEPOLIA_50GWEI;

    // Base
    if (chainId == 8453) return KEY_HASH_BASE_MAINNET_30GWEI;
    if (chainId == 84_532) return KEY_HASH_BASE_SEPOLIA_30GWEI;

    // Polygon
    if (chainId == 137) return KEY_HASH_POLYGON_MAINNET_500GWEI;
    if (chainId == 80_002) return KEY_HASH_POLYGON_AMOY_500GWEI;

    revert("Unsupported chain ID");
  }

  /// @notice Gets the network name for the given chain ID
  /// @param chainId The chain ID
  /// @return The network name
  function getNetworkName(uint256 chainId) internal pure returns (string memory) {
    // Ethereum
    if (chainId == 1) return "Ethereum Mainnet";
    if (chainId == 11_155_111) return "Ethereum Sepolia";

    // Arbitrum
    if (chainId == 42_161) return "Arbitrum Mainnet";
    if (chainId == 421_614) return "Arbitrum Sepolia";

    // Base
    if (chainId == 8453) return "Base Mainnet";
    if (chainId == 84_532) return "Base Sepolia";

    // Polygon
    if (chainId == 137) return "Polygon Mainnet";
    if (chainId == 80_002) return "Polygon Amoy";

    return "Unknown Network";
  }

  /// @notice Checks if the chain ID is supported
  /// @param chainId The chain ID to check
  /// @return True if the chain ID is supported, false otherwise
  function isSupported(uint256 chainId) internal pure returns (bool) {
    return
    // Ethereum
    chainId == 1 || chainId == 11_155_111
    // Arbitrum
    || chainId == 42_161 || chainId == 421_614
    // Base
    || chainId == 8453 || chainId == 84_532
    // Polygon
    || chainId == 137 || chainId == 80_002;
  }
}
