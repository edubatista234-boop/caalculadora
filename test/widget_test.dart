import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caalculadora/main.dart';

void main() {
  testWidgets('calculates and displays a comparison', (WidgetTester tester) async {
    await tester.pumpWidget(const InvestmentComparatorApp());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '1000');
    await tester.enterText(fields.at(1), '100');
    await tester.enterText(fields.at(2), '1');
    await tester.enterText(fields.at(3), '2000');
    await tester.enterText(fields.at(4), '50');
    await tester.enterText(fields.at(5), '0.5');
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final visibleFields = find.byType(TextFormField);
    await tester.enterText(visibleFields.last, '2');
    await tester.tap(find.text('Comparar investimentos'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo após 2 meses'), findsOneWidget);
    expect(find.text('R\$ 1221.10'), findsNWidgets(2));
    expect(find.text('R\$ 2120.30'), findsNWidgets(2));
    expect(find.text('Mês 1'), findsOneWidget);
    expect(find.text('Mês 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates required input before navigating', (WidgetTester tester) async {
    await tester.pumpWidget(const InvestmentComparatorApp());
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparar investimentos'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um valor válido.'), findsNWidgets(4));
    expect(find.text('Informe uma taxa válida.'), findsNWidgets(2));
    expect(find.text('Informe um número de meses maior que zero.'), findsOneWidget);
    expect(find.text('Resultado da comparação'), findsNothing);
  });
}
