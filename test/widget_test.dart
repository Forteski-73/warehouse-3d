// Basic smoke test: the warehouse app boots, loads the real dataset and
// shows the top bar with its title.

import 'package:flutter_test/flutter_test.dart';

import 'package:wms_3d/main.dart';

void main() {
  testWidgets('WMS 3D app boots and shows the top bar title', (WidgetTester tester) async {
    await tester.pumpWidget(const WmsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('WMS 3D — Painel do Engenheiro'), findsOneWidget);
  });
}
