import 'package:flutter/material.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';

class CompressionDialog extends StatefulWidget {
  const CompressionDialog({super.key});

  @override
  State<CompressionDialog> createState() => _CompressionDialogState();
}

class _CompressionDialogState extends State<CompressionDialog> {
  CompressionQuality? _selectedQuality;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comprimir video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Elegir el nivel de compresión.'),

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Bajo'),
                selected: _selectedQuality == CompressionQuality.low,
                onSelected: (_) {
                  setState(() {
                    _selectedQuality = CompressionQuality.low;
                  });
                },
              ),

              ChoiceChip(
                label: const Text('Medio'),
                selected: _selectedQuality == CompressionQuality.medium,
                onSelected: (_) {
                  setState(() {
                    _selectedQuality = CompressionQuality.medium;
                  });
                },
              ),

              ChoiceChip(
                label: const Text('Alto'),
                selected: _selectedQuality == CompressionQuality.high,
                onSelected: (_) {
                  setState(() {
                    _selectedQuality = CompressionQuality.high;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _selectedQuality == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    CompressionConfig(quality: _selectedQuality!),
                  );
                },
          child: const Text('Comprimir'),
        ),
      ],
    );
  }
}
