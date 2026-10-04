import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/home_permanent_password.dart';

Widget board({
  String password = 'Fixture-Pass9',
  VoidCallback? onConfigure,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: HomePermanentPassword(
          password: password,
          isSet: true,
          label: 'Permanent Password',
          configureLabel: 'Set permanent password',
          showLabel: 'Show Password',
          hideLabel: 'Hide Password',
          unavailableLabel: 'Reset password to reveal',
          accentColor: Colors.blue,
          onConfigure: onConfigure,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('home permanent password is masked and read only',
      (tester) async {
    await tester.pumpWidget(board());
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Fixture-Pass9');
    expect(field.obscureText, isTrue);
    expect(field.readOnly, isTrue);
    expect(field.autofocus, isFalse);
  });

  testWidgets('eye toggles display without changing the password',
      (tester) async {
    await tester.pumpWidget(board());
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.controller!.text, 'Fixture-Pass9');
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.controller!.text, 'Fixture-Pass9');
  });

  testWidgets('configuration button invokes the supplied dialog entry',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(board(onConfigure: () => calls++));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(calls, 1);
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
  });

  testWidgets(
      'legacy hash has a masked status but cannot reveal a fake password',
      (tester) async {
    await tester.pumpWidget(board(password: ''));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '••••••••');
    expect(find.byTooltip('Reset password to reveal'), findsOneWidget);
    final eye = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.visibility_outlined),
      matching: find.byType(InkWell),
    ));
    expect(eye.onTap, isNull);
  });

  testWidgets('password replacement returns the row to masked display',
      (tester) async {
    await tester.pumpWidget(board());
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    await tester.pumpWidget(board(password: 'Changed-Pass8'));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Changed-Pass8');
    expect(field.obscureText, isTrue);
  });

  testWidgets(
      'configuration can be disabled without disabling password display',
      (tester) async {
    await tester.pumpWidget(board());
    final configure = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.settings_outlined),
      matching: find.byType(InkWell),
    ));
    expect(configure.onTap, isNull);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
  });

  testWidgets('home row fits 200px and disposes cleanly', (tester) async {
    await tester.pumpWidget(board(
      password: List.filled(20, 'Long-Password9').join(),
    ));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
