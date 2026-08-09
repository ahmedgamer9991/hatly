import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// Reusable store category pill badge with color and icon mapping.
class CategoryBadge extends StatelessWidget {
  final String categoryName;
  final bool compact;

  const CategoryBadge({
    super.key,
    required this.categoryName,
    this.compact = false,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'pharmacy':
        return AppTheme.pharmacyColor;
      case 'bakery':
        return AppTheme.bakeryColor;
      case 'butcher':
        return AppTheme.butcherColor;
      case 'supermarket':
        return AppTheme.supermarketColor;
      default:
        return AppTheme.otherColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      case 'butcher':
        return Icons.kebab_dining_outlined;
      case 'supermarket':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
