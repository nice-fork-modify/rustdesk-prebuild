import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/connection_password.dart';

void main() {
  test('empty password keeps the existing connection password flow', () {
    expect(passwordForConnection(''), isNull);
  });

  test('nonempty passwords keep their literal values', () {
    for (final password in [
      'Mixed-Case_P@ssword123',
      '  password with spaces  ',
      '   ',
      '密码É🙂',
    ]) {
      expect(passwordForConnection(password), password);
    }
  });

  testWidgets('password field is masked without taking focus', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConnectionPasswordField(
          controller: controller,
          label: 'Password',
          onSubmitted: (_) {},
        ),
      ),
    ));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller, controller);
    expect(field.obscureText, isTrue);
    expect(field.maxLines, 1);
    expect(field.autofocus, isFalse);
    expect(field.keyboardType, TextInputType.visiblePassword);
    expect(field.textInputAction, TextInputAction.done);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.smartDashesType, SmartDashesType.disabled);
    expect(field.smartQuotesType, SmartQuotesType.disabled);
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.spellCheckConfiguration,
        const SpellCheckConfiguration.disabled());
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse);
  });

  testWidgets('editing preserves spaces and clearing restores empty behavior',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConnectionPasswordField(
          controller: controller,
          label: 'Password',
          onSubmitted: (_) {},
        ),
      ),
    ));

    const password = '  Mixed-Case_P@ss word!  ';
    await tester.enterText(find.byType(TextField), password);
    expect(controller.text, password);
    expect(passwordForConnection(controller.text), password);
    await tester.enterText(find.byType(TextField), '');
    expect(passwordForConnection(controller.text), isNull);
  });

  testWidgets('keyboard submit forwards the password once', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var submissions = 0;
    String? submittedPassword;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConnectionPasswordField(
          controller: controller,
          label: 'Password',
          onSubmitted: (_) {
            submissions++;
            submittedPassword = passwordForConnection(controller.text);
          },
        ),
      ),
    ));

    const password = '  Mixed-Case_P@ss word!  ';
    await tester.enterText(find.byType(TextField), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submissions, 1);
    expect(submittedPassword, password);
  });
}
