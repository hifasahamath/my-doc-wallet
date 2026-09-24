/// A version snapshot of a document.
class DocumentVersion {
  final String id;
  final String documentId;
  final int versionNumber;
  final String filePath;
  final String? thumbnailPath;
  final int pageCount;
  final int? fileSize;
  final String? notes;
  final DateTime createdAt;

  const DocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.filePath,
    this.thumbnailPath,
    this.pageCount = 1,
    this.fileSize,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'document_id': documentId,
        'version_number': versionNumber,
        'file_path': filePath,
        'thumbnail_path': thumbnailPath,
        'page_count': pageCount,
        'file_size': fileSize,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory DocumentVersion.fromMap(Map<String, dynamic> map) =>
      DocumentVersion(
        id: map['id'] as String,
        documentId: map['document_id'] as String,
        versionNumber: map['version_number'] as int,
        filePath: map['file_path'] as String,
        thumbnailPath: map['thumbnail_path'] as String?,
        pageCount: map['page_count'] as int? ?? 1,
        fileSize: map['file_size'] as int?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
