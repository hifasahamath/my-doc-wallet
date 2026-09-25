import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';

/// Screen for editing document metadata.
///
/// This screen is used ONLY for editing existing documents (via the
/// "Edit" action in document details). Initial document import/scan
/// no longer navigates here — documents are imported directly.
class AddEditDocumentScreen extends StatefulWidget {
  final String? documentId;

  const AddEditDocumentScreen({
    super.key,
    this.documentId,
  });

  @override
  State<AddEditDocumentScreen> createState() => _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends State<AddEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _docNumCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  
  String? _selectedCategoryId;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final catProvider = context.read<CategoryProvider>();
    final docProvider = context.read<DocumentProvider>();
    if (catProvider.categories.isEmpty) {
      await catProvider.loadCategories();
    }
    
    if (widget.documentId != null) {
      final doc = await docProvider.getDocument(widget.documentId!);
      if (doc != null && mounted) {
        setState(() {
          _nameCtrl.text = doc.name;
          _docNumCtrl.text = doc.documentNumber ?? '';
          _notesCtrl.text = doc.notes ?? '';
          _tagsCtrl.text = doc.tags.join(', ');
          _selectedCategoryId = doc.categoryId;
          _issueDate = doc.issueDate;
          _expiryDate = doc.expiryDate;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final initialDate = isExpiry 
        ? (_expiryDate ?? DateTime.now().add(const Duration(days: 365)))
        : (_issueDate ?? DateTime.now());
        
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    
    if (date != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = date;
        } else {
          _issueDate = date;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;
    
    setState(() => _isLoading = true);
    
    final tags = _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final provider = context.read<DocumentProvider>();
    
    try {
      if (widget.documentId != null) {
        final doc = await provider.getDocument(widget.documentId!);
        if (doc != null) {
          final updated = doc.copyWith(
            name: _nameCtrl.text.trim(),
            categoryId: _selectedCategoryId,
            documentNumber: _docNumCtrl.text.trim().isEmpty ? null : _docNumCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            issueDate: _issueDate,
            expiryDate: _expiryDate,
          );
          await provider.updateDocument(updated);
          await provider.setTags(updated.id, tags);
        }
      }
      
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Document Name *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _docNumCtrl,
                    decoration: const InputDecoration(labelText: 'Document Number (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Issue Date'),
                            child: Text(_issueDate != null ? _issueDate!.toIso8601String().substring(0, 10) : 'Not set'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Expiry Date'),
                            child: Text(_expiryDate != null ? _expiryDate!.toIso8601String().substring(0, 10) : 'Not set'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  
                  FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
