import 'dart:io';

const kMoneroCRepo = "https://github.com/cypherstack/salvium_c";
const kMoneroCHash = "d837147a0d6d5cd658c702266b692be44e2e4657";

final envProjectDir =
    File.fromUri(Platform.script).parent.parent.parent.parent.path;

String get envToolsDir => "$envProjectDir${Platform.pathSeparator}tools";
String get envBuildDir => "$envProjectDir${Platform.pathSeparator}build";
String get envMoneroCDir => "$envBuildDir${Platform.pathSeparator}salvium_c";
String get envOutputsDir =>
    "$envProjectDir${Platform.pathSeparator}built_outputs";
