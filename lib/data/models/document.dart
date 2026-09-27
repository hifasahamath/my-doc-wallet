import 'package:my_doc_wallet/core/utils/date_utils.dart';

/// A stored document with metadata, file reference, and expiry information.
class Document {
  final String id;
  final String name;
  final String categoryId;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final String? ocrText;
  final bool isFavorite;
  final int currentVersion;
  final String filePath;
  final String fileType; // 'pdf' or 'image'
  final String? thumbnailPath;
  final int pageCount;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime importedAt;

  // Transient — populated after query joins
  final String? categoryName;
  final List<String> tags;

  const Document({
    required this.id,
    required this.name,
    required this.categoryId,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.ocrText,
    this.isFavorite = false,
    this.currentVersion = 1,
    required this.filePath,
    required this.fileType,
    this.thumbnailPath,
    this.pageCount = 1,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    required this.importedAt,
    this.categoryName,
    this.tags = const [],
  });

  ExpiryStatus get expiryStatus => AppDateUtils.getExpiryStatus(expiryDate);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'document_number': documentNumber,
        'issue_date': AppDateUtils.formatIso(issueDate),
        'expiry_date': AppDateUtils.formatIso(expiryDate),
        'notes': notes,
        'ocr_text': ocrText,
        'is_favorite': isFavorite ? 1 : 0,
        'current_version': currentVersion,
        'file_path': filePath,
        'file_type': fileType,
        'thumbnail_path': thumbnailPath,
        'page_count': pageCount,
        'file_size': fileSize,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'imported_at': importedAt.toIso8601String(),
      };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'] as String,
        name: map['name'] as String,
        categoryId: map['category_id'] as String,
        documentNumber: map['document_number'] as String?,
        issueDate: AppDateUtils.parseIso(map['issue_date'] as String?),
        expiryDate: AppDateUtils.parseIso(map['expiry_date'] as String?),
        notes: map['notes'] as String?,
        ocrText: map['ocr_text'] as String?,
        isFavorite: (map['is_favorite'] as int?) == 1,
        currentVersion: map['current_version'] as int? ?? 1,
        filePath: map['file_path'] as String,
        fileType: map['file_type'] as String,
        thumbnailPath: map['thumbnail_path'] as String?,
        pageCount: map['page_count'] as int? ?? 1,
        fileSize: map['file_size'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        importedAt: map['imported_at'] != null 
            ? DateTime.parse(map['imported_at'] as String) 
            : DateTime.parse(map['created_at'] as String),
        categoryName: map['category_name'] as String?,
      );

  Document copyWith({
    String? name,
    String? categoryId,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    String? ocrText,
    bool? isFavorite,
    int? currentVersion,
    String? filePath,
    String? fileType,
    String? thumbnailPath,
    int? pageCount,
    int? fileSize,
    DateTime? updatedAt,
    DateTime? importedAt,
    String? categoryName,
    List<String>? tags,
    bool clearExpiryDate = false,
    bool clearIssueDate = false,
  }) =>
      Document(
        id: id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        documentNumber: documentNumber ?? this.documentNumber,
        issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
        expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
        notes: notes ?? this.notes,
        ocrText: ocrText ?? this.ocrText,
        isFavorite: isFavorite ?? this.isFavorite,
        currentVersion: currentVersion ?? this.currentVersion,
        filePath: filePath ?? this.filePath,
        fileType: fileType ?? this.fileType,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        pageCount: pageCount ?? this.pageCount,
        fileSize: fileSize ?? this.fileSize,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        importedAt: importedAt ?? this.importedAt,
        categoryName: categoryName ?? this.categoryName,
        tags: tags ?? this.tags,
      );
}
