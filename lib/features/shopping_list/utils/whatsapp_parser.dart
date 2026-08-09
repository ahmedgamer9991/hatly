import '../domain/shopping_item_model.dart';

class WhatsAppParser {
  WhatsAppParser._();

  /// Parses raw text from a WhatsApp message or paper note into a list of [ShoppingItemModel].
  static List<ShoppingItemModel> parseRawText(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText.split(RegExp(r'\r?\n'));
    final List<ShoppingItemModel> items = [];

    // Regex to remove prefix numbers like 1., 2), [3] or bullet symbols like -, *, •
    final prefixRegex = RegExp(r'^([\[\(]?\d+[\]\)\.\-\s]*|[\-\*\•\+\>]\s*)');

    int index = 0;
    for (var line in lines) {
      // Clean up the line
      String cleanedLine = line.replaceAll(prefixRegex, '').trim();

      if (cleanedLine.isNotEmpty) {
        final category = _autoDetectCategory(cleanedLine);
        items.add(
          ShoppingItemModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_$index',
            name: cleanedLine,
            category: category,
            status: 'pending',
          ),
        );
        index++;
      }
    }

    return items;
  }

  /// Simple keyword detector for Arabic/English common store keywords
  static String _autoDetectCategory(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('صيدلية') ||
        lower.contains('دواء') ||
        lower.contains('بانادول') ||
        lower.contains('علاج') ||
        lower.contains('pharmacy') ||
        lower.contains('panadol') ||
        lower.contains('medicine')) {
      return 'Pharmacy';
    }

    if (lower.contains('مخبز') ||
        lower.contains('خبز') ||
        lower.contains('عيش') ||
        lower.contains('توست') ||
        lower.contains('bakery') ||
        lower.contains('bread')) {
      return 'Bakery';
    }

    if (lower.contains('جزار') ||
        lower.contains('لحم') ||
        lower.contains('دجاج') ||
        lower.contains('فراخ') ||
        lower.contains('butcher') ||
        lower.contains('meat')) {
      return 'Butcher';
    }

    return 'Supermarket'; // Default category
  }
}
