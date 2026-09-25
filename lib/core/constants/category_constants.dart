import 'package:flutter/material.dart';

/// Built-in document categories with icons and colors.
class CategoryConstants {
  CategoryConstants._();

  static const List<CategoryDefinition> builtInCategories = [
    CategoryDefinition(
      id: 'identity',
      name: 'Identity',
      iconName: 'badge',
      color: 0xFF5C6BC0,
    ),
    CategoryDefinition(
      id: 'travel',
      name: 'Travel',
      iconName: 'flight',
      color: 0xFF26A69A,
    ),
    CategoryDefinition(
      id: 'driving',
      name: 'Driving',
      iconName: 'directions_car',
      color: 0xFFEF5350,
    ),
    CategoryDefinition(
      id: 'insurance',
      name: 'Insurance',
      iconName: 'health_and_safety',
      color: 0xFF66BB6A,
    ),
    CategoryDefinition(
      id: 'education',
      name: 'Education',
      iconName: 'school',
      color: 0xFFAB47BC,
    ),
    CategoryDefinition(
      id: 'employment',
      name: 'Employment',
      iconName: 'work',
      color: 0xFFFFA726,
    ),
    CategoryDefinition(
      id: 'finance',
      name: 'Finance',
      iconName: 'account_balance',
      color: 0xFF42A5F5,
    ),
    CategoryDefinition(
      id: 'medical',
      name: 'Medical',
      iconName: 'local_hospital',
      color: 0xFFEC407A,
    ),
    CategoryDefinition(
      id: 'property',
      name: 'Property',
      iconName: 'home',
      color: 0xFF8D6E63,
    ),
    CategoryDefinition(
      id: 'uncategorized',
      name: 'Uncategorized',
      iconName: 'folder_open',
      color: 0xFF78909C,
    ),
  ];

  /// Resolve a Material icon name string to an [IconData].
  static IconData iconFromName(String name) {
    const map = <String, IconData>{
      'badge': Icons.badge,
      'flight': Icons.flight,
      'directions_car': Icons.directions_car,
      'health_and_safety': Icons.health_and_safety,
      'school': Icons.school,
      'work': Icons.work,
      'account_balance': Icons.account_balance,
      'local_hospital': Icons.local_hospital,
      'home': Icons.home,
      'folder': Icons.folder,
      'description': Icons.description,
      'star': Icons.star,
      'favorite': Icons.favorite,
      'security': Icons.security,
      'receipt': Icons.receipt,
      'gavel': Icons.gavel,
      'inventory': Icons.inventory,
    };
    return map[name] ?? Icons.folder;
  }
}

/// Immutable definition of a document category.
class CategoryDefinition {
  final String id;
  final String name;
  final String iconName;
  final int color;

  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
  });
}
