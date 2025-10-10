import 'package:cs_salvium/cs_salvium.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import '../widgets/info_item.dart';

class CreateStakeView extends StatefulWidget {
  const CreateStakeView({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<CreateStakeView> createState() => _CreateStakeViewState();
}

class _CreateStakeViewState extends State<CreateStakeView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _lock = false;
  Future<void> preview() async {
    if (_lock) return;
    try {
      _lock = true;

      bool didError = false;

      final tx = await showLoading(
        whileFuture: widget.wallet.createStakeTx(
          output: Recipient(
            address: widget.wallet.getAddress().value,
            amount: widget.wallet.amountFromString(_amountController.text)!,
          ),
          priority: TransactionPriority.normal,
          accountIndex: 0,
        ),
        context: context,
        onError: (e, s) async {
          didError = true;
          Logging.log?.e("Stake tx failed", error: e, stackTrace: s);
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
        await showConfirmDialog(context, widget.wallet, tx!);
      }
    } catch (e, s) {
      Logging.log?.e("Preview tx failed", error: e, stackTrace: s);
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
      _lock = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stake'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    autocorrect: false,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: _amountController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Amount to Stake',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: preview,
              child: const Text("Preview"),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipientForm extends StatelessWidget {
  const RecipientForm({
    super.key,
    required this.id,
    required this.addressController,
    required this.amountController,
    required this.close,
  });

  final int id;
  final TextEditingController addressController;
  final TextEditingController amountController;
  final void Function()? close;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recipient"),
                close == null
                    ? Container()
                    : IconButton(
                        onPressed: close,
                        icon: const Icon(Icons.remove),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              autocorrect: false,
              controller: addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Address',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              autocorrect: false,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: amountController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showConfirmDialog(
  BuildContext context,
  Wallet wallet,
  PendingTransaction tx,
) async {
  bool _lock = false;
  Future<void> commit() async {
    if (_lock) return;
    try {
      _lock = true;

      bool didError = false;

      await showLoading(
        whileFuture: wallet.commitTx(tx),
        context: context,
        onError: (e, s) async {
          didError = true;
          Logging.log?.e("Commit tx failed", error: e, stackTrace: s);
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

      if (context.mounted) {
        await showAdaptiveDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog.adaptive(
            title: const Text("Success!"),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text("OK"),
              ),
            ],
          ),
        );
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e, s) {
      Logging.log?.e("Commit tx failed", error: e, stackTrace: s);
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
    } finally {
      _lock = false;
    }
  }

  return await showAdaptiveDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text("Transaction preview"),
      children: [
        InfoItem(
          label: "Amount",
          value: formattedAmount(
            tx.amount,
            wallet.runtimeType,
          ),
        ),
        InfoItem(
          label: "Fee",
          value: formattedAmount(
            tx.fee,
            wallet.runtimeType,
          ),
        ),
        InfoItem(label: "txid", value: tx.txid),
        InfoItem(label: "hex", value: tx.hex),
        const SizedBox(height: 16),
        TextButton(
          onPressed: commit,
          child: const Text("Commit tx"),
        ),
      ],
    ),
  );
}