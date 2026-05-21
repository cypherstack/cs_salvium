import 'package:flutter/material.dart';

class InfoItem extends StatelessWidget {
  const InfoItem({super.key, this.label, this.value});

  final dynamic label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("$label: "),
              const SizedBox(
                height: 10,
              ),
              SelectableText(value.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
