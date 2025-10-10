import 'dart:io';

/// Global application configuration.
/// Call [AppConfig.initialize] once at startup before runApp().
class AppConfig {
  // ─────────────────────────────────────────────────────────────────────────────
  // Network modes
  static const int mainnet = 0;
  static const int testnet = 1;
  static const int stagenet = 2;

  static bool _isInitialized = false;
  static late final int network;      // 0=mainnet, 1=testnet, 2=stagenet
  static late final String modeString;
  static late final int rpcPort;
  static late final String rpcAddress;

  static bool get isInitialized => _isInitialized;
  static bool get isMainnet => network == mainnet;
  static bool get isTestnet => network == testnet;
  static bool get isStagenet => network == stagenet;

  // ─────────────────────────────────────────────────────────────────────────────
  /// Initializes configuration based on CLI args or environment variable APP_MODE.
  static Future<void> initialize(List<String> args) async {
    if (_isInitialized) return;

    String? detectedMode;

    // 1️⃣ Try CLI argument
    if (args.isNotEmpty) {
      detectedMode = args.first.trim().toLowerCase();
      stdout.writeln("Command-line arg found: $detectedMode");
    } else {
      // 2️⃣ Fallback to environment variable
      detectedMode = Platform.environment['APP_MODE']?.toLowerCase();
      if (detectedMode != null) {
        stdout.writeln("Environment variable found: $detectedMode");
      } else {
        stdout.writeln("No mode specified — defaulting to mainnet");
      }
    }

    // 3️⃣ Normalize and assign network parameters
    switch (detectedMode) {
      case 'testnet':
        network = testnet;
        modeString = 'testnet';
        rpcPort = 29081;
        break;
      case 'stagenet':
        network = stagenet;
        modeString = 'stagenet';
        rpcPort = 39081;
        break;
      case 'mainnet':
      default:
        network = mainnet;
        modeString = 'mainnet';
        rpcPort = 19081;
    }

    // 4️⃣ Construct RPC address (can easily extend later)
    rpcAddress = "localhost:$rpcPort";

    _isInitialized = true;

    stdout.writeln("🌐 Network mode: $modeString ($network)");
    stdout.writeln("🔌 RPC endpoint: $rpcAddress");
  }
}
