import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool isSelected;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.onDeleted,
    this.isSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceVariant,
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingSmall),
    );
  }
}
