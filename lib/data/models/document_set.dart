/// A document set (e.g. travel trip, job application, visa application).
class DocumentSet {
  final String id;
  final String name;
  final String? description;
  final String setType; // 'travel', 'job_application', 'visa', 'insurance', 'custom'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient
  final int documentCount;

  const DocumentSet({
    required this.id,
    required this.name,
    this.description,
    required this.setType,
    required this.createdAt,
    required this.updatedAt,
    this.documentCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'set_type': setType,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DocumentSet.fromMap(Map<String, dynamic> map) => DocumentSet(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        setType: map['set_type'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        documentCount: map['document_count'] as int? ?? 0,
      );

  DocumentSet copyWith({
    String? name,
    String? description,
    String? setType,
    DateTime? updatedAt,
  }) =>
      DocumentSet(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        setType: setType ?? this.setType,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        documentCount: documentCount,
      );

  static const List<String> setTypes = [
    'travel',
    'job_application',
    'visa',
    'insurance',
    'university',
    'custom',
  ];

  static String setTypeLabel(String type) {
    switch (type) {
      case 'travel':
        return 'Travel / Trip';
      case 'job_application':
        return 'Job Application';
      case 'visa':
        return 'Visa Application';
      case 'insurance':
        return 'Insurance Claim';
      case 'university':
        return 'University Application';
      case 'custom':
        return 'Custom';
      default:
        return type;
    }
  }
}
