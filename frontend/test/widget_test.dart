import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/main.dart';

void main() {
  testWidgets('app renders splash text', (tester) async {
    await tester.pumpWidget(const TileZhanApp());
    expect(find.text('TILEZHAN'), findsOneWidget);
    expect(find.text('🀄'), findsOneWidget);
  });
}
