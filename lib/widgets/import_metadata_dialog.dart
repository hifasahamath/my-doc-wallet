import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/category_provider.dart';

/// A dialog shown during the import/scan flow allowing the user to optionally
/// set the document's Title, Category, and Expiry Date before saving.
///
/// Returns a map with keys 'title' (String?), 'categoryId' (String?),
/// and 'expiryDate' (DateTime?) if the user proceeds, or null if cancelled.
class ImportMetadataDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialCategoryId;

  const ImportMetadataDialog({
    super.key,
    this.initialTitle,
    this.initialCategoryId,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialTitle,
    String? initialCategoryId,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImportMetadataDialog(
        initialTitle: initialTitle,
        initialCategoryId: initialCategoryId,
      ),
    );
  }

  @override
  State<ImportMetadataDialog> createState() => _ImportMetadataDialogState();
}

class _ImportMetadataDialogState extends State<ImportMetadataDialog> {
  late final TextEditingController _titleCtrl;
  String? _selectedCategoryId;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return AlertDialog(
      title: const Text('Document Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can optionally set these details now, or edit them later.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Document Title (Optional)',
                hintText: 'e.g., Passport 2026',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId ?? 'uncategorized',
              decoration: const InputDecoration(labelText: 'Category (Optional)'),
              items: categories.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                ),
              ).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectExpiryDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expiry Date (Optional)',
                  suffixIcon: _expiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _expiryDate = null),
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _expiryDate != null
                      ? _expiryDate!.toIso8601String().substring(0, 10)
                      : 'No Expiry',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
              'categoryId': _selectedCategoryId,
              'expiryDate': _expiryDate,
            });
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}
