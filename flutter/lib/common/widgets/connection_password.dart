import 'package:flutter/material.dart';

String? passwordForConnection(String password) {
  return password.isEmpty ? null : password;
}

class ConnectionPasswordField extends StatelessWidget {
  const ConnectionPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmitted,
    this.style,
    this.filled,
    this.textAlignVertical,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;
  final TextStyle? style;
  final bool? filled;
  final TextAlignVertical? textAlignVertical;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: style,
      textAlignVertical: textAlignVertical,
      obscureText: true,
      maxLines: 1,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      enableIMEPersonalizedLearning: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      decoration: InputDecoration(
        filled: filled,
        hintText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
