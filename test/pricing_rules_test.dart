import 'package:flutter_test/flutter_test.dart';
import 'package:outo_deals_iraq/legacy_main.dart' as legacy;

void main() {
  group('Tire pricing rules', () {
    test('low tier uses 10k shop profit and 3k commission', () {
      const tire = legacy.Tire('test', 90000);
      expect(tire.profit, 10000);
      expect(tire.commission, 3000);
      expect(tire.price, 103000);
    });

    test('mid tier commission changes at 100k', () {
      const tire = legacy.Tire('test', 120000);
      expect(tire.profit, 10000);
      expect(tire.commission, 4000);
      expect(tire.price, 134000);
    });

    test('shop profit becomes 12k at 150k', () {
      const tire = legacy.Tire('test', 150000);
      expect(tire.profit, 12000);
      expect(tire.commission, 5000);
      expect(tire.price, 167000);
    });

    test('shop profit becomes 15k at 200k', () {
      const tire = legacy.Tire('test', 200000);
      expect(tire.profit, 15000);
      expect(tire.commission, 5000);
      expect(tire.price, 220000);
    });
  });

  group('Battery pricing rules', () {
    test('old battery return removes 10k shop profit', () {
      const battery = legacy.Battery('test', '70', 50000);
      expect(battery.withOld, 53000);
      expect(battery.withoutOld, 63000);
      expect(battery.withoutOld - battery.withOld, 10000);
    });
  });

  test('catalog prices are never below wholesale', () {
    for (final tire in legacy.tires) {
      expect(tire.price, greaterThan(tire.wholesale));
    }
    for (final battery in legacy.batteries) {
      expect(battery.withOld, greaterThanOrEqualTo(battery.wholesale));
      expect(battery.withoutOld, greaterThan(battery.wholesale));
    }
  });
}
