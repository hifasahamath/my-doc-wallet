/// A document category (built-in or user-created).
class Category {
  final String id;
  final String name;
  final String iconName;
  final int color;
  final bool isCustom;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.isCustom = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': iconName,
        'color': color,
        'is_custom': isCustom ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        iconName: map['icon'] as String,
        color: map['color'] as int,
        isCustom: (map['is_custom'] as int) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  Category copyWith({
    String? name,
    String? iconName,
    int? color,
    int? sortOrder,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        color: color ?? this.color,
        isCustom: isCustom,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
