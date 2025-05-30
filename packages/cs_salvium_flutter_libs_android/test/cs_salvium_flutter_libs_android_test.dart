import 'package:cs_salvium_flutter_libs_android/cs_salvium_flutter_libs_android.dart';
import 'package:cs_salvium_flutter_libs_platform_interface/cs_salvium_flutter_libs_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("$CsSalviumFlutterLibsAndroid", () {
    final platform = CsSalviumFlutterLibsAndroid();
    const MethodChannel channel =
        MethodChannel("cs_salvium_flutter_libs_android");

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          return "42";
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test("getPlatformVersion", () async {
      expect(
        await platform.getPlatformVersion(
          overrideForBasicTestCoverageTesting: true,
        ),
        "42",
      );
    });
  });

  test("registerWith", () {
    CsSalviumFlutterLibsAndroid.registerWith();
    expect(
      CsSalviumFlutterLibsPlatform.instance,
      isA<CsSalviumFlutterLibsAndroid>(),
    );
  });
}
