import 'dart:io';

import '../env.dart';
import '../util.dart';

void main() async {
  final compiledLibsDir = Directory(envOutputsDir);
  await _copyCompiledToFinalLocations(compiledLibsDir);
}

Future<void> _copyCompiledToFinalLocations(Directory compiledLibsDir) async {
  if (!await compiledLibsDir.exists()) {
    throw Exception(
      "Error: The provided compiled outputs directory does not exist.",
    );
  }

  final libsPackagePrefix =
      "$envProjectDir${Platform.pathSeparator}packages${Platform.pathSeparator}cs_salvium_flutter_libs";

  // Android
  for (final arch in ["armeabi-v7a", "arm64-v8a", "x86_64"]) {
    final compiled = Directory(
      "${compiledLibsDir.path}"
      "${Platform.pathSeparator}android"
      "${Platform.pathSeparator}jniLibs"
      "${Platform.pathSeparator}$arch",
    );
    if (compiled.existsSync()) {
      final libsDir = Directory(
        "${libsPackagePrefix}_android_${arch.replaceAll("-", "_")}"
        "${Platform.pathSeparator}android"
        "${Platform.pathSeparator}src"
        "${Platform.pathSeparator}main"
        "${Platform.pathSeparator}jniLibs"
        "${Platform.pathSeparator}$arch",
      );
      await runAsync("rm", ["-rf", libsDir.path]);
      await runAsync("cp", ["-r", compiled.path, libsDir.path]);
      l("Copied android $arch libs.");
    } else {
      l("Copy android libs failed. No compiled libs found.");
    }
  }

  // iOS & macOS
  for (final os in ["ios", "macos"]) {
    final compiled = Directory(
      "${compiledLibsDir.path}"
      "${Platform.pathSeparator}$os"
      "${Platform.pathSeparator}Frameworks",
    );
    if (compiled.existsSync()) {
      final libsDir = Directory(
        "${libsPackagePrefix}_$os"
        "${Platform.pathSeparator}$os"
        "${Platform.pathSeparator}Frameworks",
      );
      await runAsync("rm", ["-rf", libsDir.path]);
      await runAsync("rsync", ["-a", compiled.path, libsDir.parent.path]);
      l("Copied $os libs.");
    } else {
      l("Copy $os libs failed. No compiled libs found.");
    }
  }

  // Windows & Linux
  for (final os in ["windows", "linux"]) {
    final compiled = Directory(
      "${compiledLibsDir.path}"
      "${Platform.pathSeparator}$os",
    );
    if (compiled.existsSync()) {
      final libsDir = Directory(
        "${libsPackagePrefix}_$os"
        "${Platform.pathSeparator}$os"
        "${Platform.pathSeparator}lib",
      );
      await runAsync("rm", ["-rf", libsDir.path]);
      await runAsync("cp", ["-r", compiled.path, libsDir.path]);
      l("Copied $os libs.");
    } else {
      l("Copy $os libs failed. No compiled libs found.");
    }
  }
}
