import 'package:flutter_test/flutter_test.dart';
import 'package:hatly/features/shopping_list/utils/whatsapp_parser.dart';

void main() {
  group('WhatsAppParser Unit Tests', () {
    test('Parse empty text returns empty list', () {
      final items = WhatsAppParser.parseRawText('   ');
      expect(items, isEmpty);
    });

    test('Parse multiline text with prefixes correctly strips numbers and symbols', () {
      const rawText = '''
1. حليب كامل الدسم
2) جبنة بيضاء
[3] عيش بلدي
- صابون غسيل
• بانادول من الصيدلية
''';

      final items = WhatsAppParser.parseRawText(rawText);

      expect(items.length, equals(5));
      expect(items[0].name, equals('حليب كامل الدسم'));
      expect(items[1].name, equals('جبنة بيضاء'));
      expect(items[2].name, equals('عيش بلدي'));
      expect(items[3].name, equals('صابون غسيل'));
      expect(items[4].name, equals('بانادول من الصيدلية'));
    });

    test('Auto-detects store categories based on Arabic keywords', () {
      const rawText = '''
بانادول للاطفال
خبز توست طازج
كيلو لحم مفروم من الجزار
حليب وطماطم
''';

      final items = WhatsAppParser.parseRawText(rawText);

      expect(items[0].category, equals('Pharmacy'));
      expect(items[1].category, equals('Bakery'));
      expect(items[2].category, equals('Butcher'));
      expect(items[3].category, equals('Supermarket'));
    });
  });
}
