import 'package:cs_salvium_flutter_libs_platform_interface/cs_salvium_flutter_libs_platform_interface.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('cs_salvium_flutter_libs_ios');

class CsSalviumFlutterLibsIos extends CsSalviumFlutterLibsPlatform {
  /// Registers this class as the default instance of [CsSalviumFlutterLibsPlatform].
  static void registerWith() {
    CsSalviumFlutterLibsPlatform.instance = CsSalviumFlutterLibsIos();
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await _channel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
