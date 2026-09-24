/// A custom metadata field attached to a document.
class CustomField {
  final String id;
  final String documentId;
  final String fieldName;
  final String fieldValue;

  const CustomField({
    required this.id,
    required this.documentId,
    required this.fieldName,
    required this.fieldValue,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'document_id': documentId,
        'field_name': fieldName,
        'field_value': fieldValue,
      };

  factory CustomField.fromMap(Map<String, dynamic> map) => CustomField(
        id: map['id'] as String,
        documentId: map['document_id'] as String,
        fieldName: map['field_name'] as String,
        fieldValue: map['field_value'] as String,
      );
}
