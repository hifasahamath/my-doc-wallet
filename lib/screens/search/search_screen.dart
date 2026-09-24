import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/search_provider.dart';
import 'package:my_doc_wallet/widgets/document_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';

/// Screen for searching documents across metadata and OCR text.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<SearchProvider>().search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by name, tag, notes, or text...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.clear();
                    },
                  )
                : null,
          ),
          style: theme.textTheme.titleMedium,
          onChanged: _onSearchChanged,
        ),
      ),
      body: provider.isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchCtrl.text.trim().isEmpty
              ? const EmptyState(
                  icon: Icons.search,
                  title: 'Search Documents',
                  subtitle: 'Find documents by name, tags, or content.',
                )
              : provider.results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'No results',
                      subtitle: 'No documents match "${_searchCtrl.text}"',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: provider.results.length,
                      itemBuilder: (context, index) {
                        final doc = provider.results[index];
                        return DocumentCard(
                          document: doc,
                          onTap: () => context.push('/document/${doc.id}'),
                        );
                      },
                    ),
    );
  }
}
