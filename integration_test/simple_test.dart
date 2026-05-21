import 'package:flutter_test/flutter_test.dart';
import 'package:librarymanagementsystem/app_widget.dart';
import 'package:librarymanagementsystem/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  testWidgets('Can initialize application', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());
    expect(find.byType(AppWidget), findsOneWidget);
  });
}
