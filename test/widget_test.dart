import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProjectLBSNAAApp()));
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
