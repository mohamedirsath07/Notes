import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String? hint;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hint,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Notes'),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Enter search terms...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() {}),
        onSubmitted: (value) => _performSearch(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _performSearch, child: const Text('Search')),
      ],
    );
  }

  void _performSearch() {
    widget.onSearch(widget.controller.text.trim());
  }
}
