// ignore_for_file: lines_longer_than_80_chars

/// Default staking list configuration
///
/// This file contains the default staking configurations and parameters
/// used throughout the application for staking operations.
class StakingConfig {
  final String name;
  final String description;
  final String tailHash;
  final int minStakingAmount;
  final double apy;
  final String logoUrl;
  final bool isActive;
  final String contractAddress;

  const StakingConfig({
    required this.name,
    required this.description,
    required this.tailHash,
    required this.minStakingAmount,
    required this.apy,
    required this.logoUrl,
    required this.isActive,
    required this.contractAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'tailHash': tailHash,
      'minStakingAmount': minStakingAmount,
      'apy': apy,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'contractAddress': contractAddress,
    };
  }

  factory StakingConfig.fromJson(Map<String, dynamic> json) {
    return StakingConfig(
      name: json['name'] as String,
      description: json['description'] as String,
      tailHash: json['tailHash'] as String,
      minStakingAmount: json['minStakingAmount'] as int,
      apy: json['apy'] as double,
      logoUrl: json['logoUrl'] as String,
      isActive: json['isActive'] as bool,
      contractAddress: json['contractAddress'] as String,
    );
  }

  @override
  String toString() {
    return 'StakingConfig(name: $name, description: $description, tailHash: $tailHash, minStakingAmount: $minStakingAmount, apy: $apy, logoUrl: $logoUrl, isActive: $isActive, contractAddress: $contractAddress)';
  }
}

/// Default staking list containing common staking configurations
///
/// This list provides default staking options that can be used
/// throughout the application. Each entry contains the necessary
/// information for staking operations including minimum amounts,
/// APY rates, and contract addresses.
///
/// Uses real tailHash values from defaultTokens configuration
final List<StakingConfig> stakingList = [
  StakingConfig(
    name: 'BEPE Staking',
    description: 'Stake BEPE tokens to earn rewards',
    tailHash: 'ccda69ff6c44d687994efdbee30689be51d2347f739287ab4bb7b52344f8bf1d',
    minStakingAmount: 1000000, // 1 BEPE (assuming 6 decimals)
    apy: 12.5,
    logoUrl:
        'https://assets.spacescan.io/cat/30f32a7fab37f11707a754a04ff99290f8941db02b7667edd75b1b826485753f.webp',
    isActive: false,
    contractAddress: 'txch1bepestakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'HOA COIN Staking',
    description: 'Stake HOA COIN for platform rewards',
    tailHash: 'e816ee18ce2337c4128449bc539fbbe2ecfdd2098c4e7cab4667e223c3bdc23d',
    minStakingAmount: 1000000, // 1 HOA (assuming 6 decimals)
    apy: 15.0,
    logoUrl:
        'https://assets.spacescan.io/cat/5e166eac0d7c591cfa57c125af32b16603d1d2ca3dc81bd753c6d410c83834e8.webp',
    isActive: false,
    contractAddress: 'txch1hoastakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'PP Staking',
    description: 'Stake PP tokens for platform benefits',
    tailHash: '84d31c80c619070ba45ce4dc5cc0bed2ae4341a0da1d69504e28243e6ccbef37',
    minStakingAmount: 1000000, // 1 PP (assuming 6 decimals)
    apy: 10.0,
    logoUrl:
        'https://assets.spacescan.io/cat/68c97f0dabfee561b4f38a1ac672cead22e583019804d07653810ce7f1b7bffe.webp',
    isActive: false,
    contractAddress: 'txch1ppstakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: '☕ Coffee Staking',
    description: 'Stake Coffee tokens for daily rewards',
    tailHash: '14feb393ffb015b7becf2c1eea218e4fbfef0bb932366b793d7c5193a8197358',
    minStakingAmount: 1000000, // 1 COFFEE (assuming 6 decimals)
    apy: 8.5,
    logoUrl:
        'https://assets.spacescan.io/cat/5a2a6a20d3b6b866de7a0908cb713aef92c62dda8b25df7073040203176987f3.webp',
    isActive: true,
    contractAddress: 'txch1coffeestakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'CHAD Staking',
    description: 'Stake CHAD tokens for governance rewards',
    tailHash: '0941dc178e75d3699fab42a002034cae455ba5dfc91a9a9f58b62c48c9cea754',
    minStakingAmount: 1000000, // 1 CHAD (assuming 6 decimals)
    apy: 18.0,
    logoUrl:
        'https://assets.spacescan.io/cat/0941dc178e75d3699fab42a002034cae455ba5dfc91a9a9f58b62c48c9cea754.jpg',
    isActive: false,
    contractAddress: 'txch1chadstakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'STONKS Staking',
    description: 'Stake STONKS for market rewards',
    tailHash: 'bf96d9d1a1973d41047e74d43117799d5b63b275c8f26921e6228ec84b553da9',
    minStakingAmount: 1000000, // 1 STONKS (assuming 6 decimals)
    apy: 22.0,
    logoUrl:
        'https://assets.spacescan.io/cat/9ce8a90d9e0a0d63041cb5c30e565f66a1a8c144219a6107dca7313d5037b205.webp',
    isActive: false,
    contractAddress: 'txch1stonksstakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'Marmot Wif Hat Staking',
    description: 'Stake MWIF tokens for community rewards',
    tailHash: 'e233f9c0ebc092f083aaacf6295402ed0a0bb1f9acb1b56500d8a4f5a5e4c957',
    minStakingAmount: 1000000, // 1 MWIF (assuming 6 decimals)
    apy: 14.5,
    logoUrl:
        'https://assets.spacescan.io/cat/5641f4abc0656b0308998b87b1d8b703f7bda5e2efa91834f9752dc7f5821b50.webp',
    isActive: false,
    contractAddress: 'txch1marmotstakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: '🐈 PUSSY Staking',
    description: 'Stake PUSSY tokens for meme rewards',
    tailHash: '3c6da5ae38438db6299426402dc23f9436ee085270ed76f8fc7f9e6b4136dca2',
    minStakingAmount: 1000000, // 1 PUSSY (assuming 6 decimals)
    apy: 16.0,
    logoUrl:
        'https://assets.spacescan.io/cat/27f84fe5fc087af568a6c6078f84a5410112521cb038313fa93ec7b195c60f1b.webp',
    isActive: false,
    contractAddress: 'txch1pussystakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'CTK Staking',
    description: 'Stake CTK tokens for governance rewards',
    tailHash: '482b49902d310c53065c3531d398d41808f1390590d566815d67040f6a32d124',
    minStakingAmount: 2000000, // 2 CTK (assuming 6 decimals)
    apy: 10.0,
    logoUrl: 'https://example.com/ctk-logo.png',
    isActive: false,
    contractAddress: 'txch1ctkstakingcontractaddress1234567890abcdef',
  ),
  StakingConfig(
    name: 'TRZ Staking',
    description: 'Stake TRZ tokens for meme rewards',
    tailHash: '478b66e6f3c033a12ad43e354329a2f54c187503a4025abdb3b3824f92ca0819',
    minStakingAmount: 1000000, // 1 TRZ (assuming 6 decimals)
    apy: 12.0,
    logoUrl:
        'https://assets-fin.spacescan.io/nft/609459ff1352c5011ed87a864041297043a61c5dccd0b21ad65883149ff700c5.webp',
    isActive: false,
    contractAddress: 'txch1trzstakingcontractaddress1234567890abcdef',
  ),
];

/// Get staking config by tail hash
///
/// [tailHash] - The tail hash of the staking token
/// Returns the staking configuration for the given tail hash, or null if not found
StakingConfig? getStakingConfigByTailHash(String tailHash) {
  try {
    return stakingList.firstWhere(
      (config) => config.tailHash.toLowerCase() == tailHash.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Get active staking configurations
///
/// Returns a list of all active staking configurations
List<StakingConfig> getActiveStakingConfigs() {
  return stakingList.where((config) => config.isActive).toList();
}

/// Get staking config by name
///
/// [name] - The name of the staking configuration
/// Returns the staking configuration for the given name, or null if not found
StakingConfig? getStakingConfigByName(String name) {
  try {
    return stakingList.firstWhere(
      (config) => config.name.toLowerCase() == name.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Get staking configs with minimum APY
///
/// [minApy] - The minimum APY threshold
/// Returns a list of staking configurations with APY greater than or equal to the threshold
List<StakingConfig> getStakingConfigsWithMinApy(double minApy) {
  return stakingList.where((config) => config.apy >= minApy).toList();
}

/// Get staking configs by minimum staking amount
///
/// [maxMinAmount] - The maximum minimum staking amount
/// Returns a list of staking configurations with minimum staking amount less than or equal to the threshold
List<StakingConfig> getStakingConfigsByMaxMinAmount(int maxMinAmount) {
  return stakingList.where((config) => config.minStakingAmount <= maxMinAmount).toList();
}
