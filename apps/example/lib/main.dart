import 'dart:core' as core;
import 'dart:core';

import 'package:cs_salvium/cs_salvium.dart';
import 'package:cs_salvium_flutter_libs/cs_salvium_flutter_libs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';

import 'views/create_view_only_wallet_view.dart';
import 'views/create_wallet_view.dart';
import 'views/open_wallet_view.dart';
import 'views/restore_deterministic_from_spend_key_view.dart';
import 'views/restore_from_keys_view.dart';
import 'views/restore_from_seed_view.dart';

Future<void> main(List<String> args) async {

  // Initialize config before launching app
  await AppConfig.initialize(args);

  WidgetsFlutterBinding.ensureInitialized();

  Logging.useLogger = true;

  runApp(
    const MaterialApp(
      home: ExampleApp(),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String? _platformVersion = 'Unknown';

  Future<void> initPlatformState() async {
    String? platformVersion;
    try {
      platformVersion = await CsSalviumFlutterLibs().getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('cs_salvium example app'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => const CreateWalletView(),
                      ),
                    );
                  },
                  child: const Text("Create a wallet"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => const OpenWalletView(),
                      ),
                    );
                  },
                  child: const Text("Open a wallet"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => const RestoreFromSeedView(),
                      ),
                    );
                  },
                  child: const Text("Restore from seed"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => const RestoreFromKeysView(),
                      ),
                    );
                  },
                  child: const Text("Restore from keys"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) =>
                            const RestoreDeterministicFromSpendKeyView(),
                      ),
                    );
                  },
                  child: const Text("Restore deterministic from spend key"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => const CreateViewOnlyWalletView(),
                      ),
                    );
                  },
                  child: const Text("Create View Only wallet"),
                ),
              ],
            ),
          ),
          Text(
            'Running on: $_platformVersion',
          ),
        ],
      ),
    );
  }
}
