import 'dart:io';

import '../env.dart';
import '../util.dart';

void main() async {
  await createBuildDirs();

  final moneroCDir = Directory(envSalviumCDir);
  if (moneroCDir.existsSync()) {
    // TODO: something?
    l("salvium_c dir already exists");
    return;
  } else {
    // Change directory to BUILD_DIR
    Directory.current = envBuildDir;

    // Clone the salvium_c repository
    await runAsync('git', [
      'clone',
      kSalviumCRepo,
      '--branch',
      'apple-frameworks',
    ]);

    // Change directory to MONERO_C_DIR
    Directory.current = moneroCDir;

    // Checkout specific commit and reset
    await runAsync('git', ['checkout', kSalviumCHash]);
    await runAsync('git', ['reset', '--hard']);

    // Configure submodules
    await runAsync('git', [
      'config',
      'submodule.libs/wownero.url',
      'https://git.cypherstack.com/cypherstack/wownero',
    ]);
    await runAsync('git', [
      'config',
      'submodule.libs/wownero-seed.url',
      'https://git.cypherstack.com/cypherstack/wownero-seed',
    ]);

    // Update submodules
    await runAsync(
      'git',
      ['submodule', 'update', '--init', '--force', '--recursive'],
    );

    // Apply patches
    await runAsync('./apply_patches.sh', ['monero']);
    await runAsync('./apply_patches.sh', ['wownero']);
  }
}
