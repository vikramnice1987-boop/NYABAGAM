import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/app/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders NyabagamApp successfully', (tester) async {
    await tester.pumpWidget(const NyabagamApp());
    await tester.pumpAndSettle();
    expect(find.text('NYABAGAM'), findsOneWidget);
  });
}