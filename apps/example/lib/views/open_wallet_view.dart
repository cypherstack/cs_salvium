import 'package:cs_salvium/cs_salvium.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../util.dart';
import 'wallet_view.dart';

class OpenWalletView extends StatefulWidget {
  const OpenWalletView({super.key});

  @override
  State<OpenWalletView> createState() => _OpenWalletViewState();
}

class _OpenWalletViewState extends State<OpenWalletView> {
  Future<List<String>> getAll() async {
    final salvium = await loadWalletNames("salvium");
    // final wownero = await loadWalletNames("wownero");

    return salvium.map((e) => "Salvium: $e").toList();
      // ..addAll(
      //   wownero.map((e) => "Wownero: $e"),
      // );
  }

  @override
  void initState() {
    super.initState();
    getAll().then((all) {
      setState(() {
        names = all;
      });
    });
  }

  List<String>? names;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open wallet'),
        centerTitle: true,
      ),
      body: names == null
          ? const Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(),
              ),
            )
          : names!.isEmpty
              ? const Center(
                  child: Text("No wallets found"),
                )
              : ListView.builder(
                  itemCount: names!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(names![index]),
                      onTap: () {
                        final actualName = names![index].substring(9);
                        final String type;
                        // if (names![index].startsWith("Sal")) {
                          type = "salvium";
                        // } else {
                        //   type = "wownero";
                        // }
                        showAdaptiveDialog<void>(
                          context: context,
                          builder: (context) => OpenWalletDialog(
                            type: type,
                            name: actualName,
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class OpenWalletDialog extends StatefulWidget {
  const OpenWalletDialog({super.key, required this.type, required this.name});

  final String type;
  final String name;

  @override
  State<OpenWalletDialog> createState() => _OpenWalletDialogState();
}

class _OpenWalletDialogState extends State<OpenWalletDialog> {
  late final TextEditingController controller;

  Future<Wallet> _helperFuture(
    String name,
    String type,
    String pw,
  ) async {
    final path = await pathForWallet(
      name: name,
      type: type,
      createIfNotExists: false,
    );
    final Wallet wallet;
    final String daemonAddress;
    switch (type) {
      case "salvium":
        daemonAddress = AppConfig.rpcAddress;
        wallet = await SalviumWallet.loadWallet(
          path: path,
          password: pw,
          networkType: AppConfig.network,
        );
        break;

      default:
        throw Exception("Unknown wallet type: $type");
    }
    await wallet.connect(
      daemonAddress: daemonAddress,
      trusted: true,
      useSSL: false,
    );

    return wallet;
  }

  bool _locked = false;

  Future<void> _onPressed(String type, String name, String pw) async {
    if (_locked) return;
    setState(() {
      _locked = true;
    });

    try {
      bool didError = false;
      final wallet = await showLoading(
        whileFuture: _helperFuture(name, type, pw),
        context: context,
        onError: (e, s) async {
          didError = true;
          Logging.log?.e("Open wallet failed", error: e, stackTrace: s);
          if (context.mounted) {
            await showAdaptiveDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => AlertDialog.adaptive(
                title: Text(e.toString()),
                content: Text(s.toString()),
              ),
            );
          }
        },
      );

      if (didError) return;

      if (mounted) {
        if (wallet != null) {
          wallet.startSyncing();
          // pop dialog
          Navigator.of(context).pop();
          await Navigator.of(context).push(
            MaterialPageRoute<dynamic>(
              builder: (context) => WalletView(
                wallet: wallet,
              ),
            ),
          );
        } else {
          await showAdaptiveDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (_) => const AlertDialog.adaptive(
              title: Text("Failed to connect/wallet is null"),
            ),
          );
        }
      }
    } catch (e, s) {
      if (mounted) {
        await showAdaptiveDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog.adaptive(
            title: Text(e.toString()),
            content: Text(s.toString()),
          ),
        );
      }
    } finally {
      _locked = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Open \"${widget.name}\" (${widget.type}) wallet"),
                const SizedBox(height: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    _onPressed(
                      widget.type,
                      widget.name,
                      controller.text,
                    );
                  },
                  child: const Text("Open"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
