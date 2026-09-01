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
      title: const Center(
        child: Text(
          'Elegir el nivel de compresión',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSwitchOption(
                  label: 'Alto',
                  quality: CompressionQuality.low,
                ),
                const SizedBox(height: 10),
                _buildSwitchOption(
                  label: 'Medio',
                  quality: CompressionQuality.medium,
                ),
                const SizedBox(height: 10),
                _buildSwitchOption(
                  label: 'Bajo',
                  quality: CompressionQuality.high,
                ),
              ],
            ),
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

  Widget _buildSwitchOption({
    required String label,
    required CompressionQuality quality,
  }) {
    final isSelected = _selectedQuality == quality;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedQuality = isSelected ? null : quality;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[800]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[300],
              ),
            ),
            Switch(
              value: isSelected,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.blue,
              onChanged: (val) {
                setState(() {
                  _selectedQuality = val ? quality : null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
