import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outo_deals_iraq/vehicle_catalog.dart';
import 'package:outo_deals_iraq/vehdb_cars_page.dart';

void main() {
  test('Each bundled make has distinct nonempty model choices', () {
    expect(vehicleCatalog['Toyota'], containsAll(['Camry', 'Corolla']));
    expect(vehicleCatalog['Kia'], contains('Sportage'));
    for (final entry in vehicleCatalog.entries) {
      expect(entry.key.trim(), isNotEmpty);
      expect(entry.value, isNotEmpty, reason: entry.key);
      expect(entry.value.every((value) => value.trim().isNotEmpty), isTrue);
      expect(entry.value.toSet().length, entry.value.length);
    }
  });

  testWidgets('Offline selectors reset model and year when make changes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VehDbCarsPage()));
    final stringFields = find.byType(DropdownButtonFormField<String>);
    tester.widget<DropdownButtonFormField<String>>(stringFields.first)
        .onChanged!('Toyota');
    await tester.pump();
    var models = tester.widget<DropdownButtonFormField<String>>(stringFields.last);
    var choices = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).last,
    ).items!.map((item) => item.value);
    expect(choices, contains('Camry'));
    expect(find.byType(TextField), findsNothing);
    models.onChanged!('Camry');
    await tester.pump();
    tester.widget<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    ).onChanged!(2020);
    await tester.pump();
    expect(find.text('بحث عن السيارة والفئة'), findsOneWidget);

    tester.widget<DropdownButtonFormField<String>>(stringFields.first)
        .onChanged!('Kia');
    await tester.pump();
    models = tester.widget<DropdownButtonFormField<String>>(stringFields.last);
    choices = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).last,
    ).items!.map((item) => item.value);
    expect(choices, contains('Sportage'));
    expect(choices, isNot(contains('Camry')));
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('بحث عن السيارة والفئة'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
