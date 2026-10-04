import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePermanentPassword extends StatefulWidget {
  const HomePermanentPassword({
    super.key,
    required this.password,
    required this.isSet,
    required this.label,
    required this.configureLabel,
    required this.showLabel,
    required this.hideLabel,
    required this.unavailableLabel,
    required this.accentColor,
    required this.onConfigure,
  });

  final String password;
  final bool isSet;
  final String label;
  final String configureLabel;
  final String showLabel;
  final String hideLabel;
  final String unavailableLabel;
  final Color accentColor;
  final VoidCallback? onConfigure;

  @override
  State<HomePermanentPassword> createState() => _HomePermanentPasswordState();
}

class _HomePermanentPasswordState extends State<HomePermanentPassword> {
  final _controller = TextEditingController();
  bool _visible = false;
  bool _configureHover = false;
  bool _eyeHover = false;

  @override
  void initState() {
    super.initState();
    _updateText();
  }

  @override
  void didUpdateWidget(HomePermanentPassword oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password ||
        oldWidget.isSet != widget.isSet) {
      _visible = false;
      _updateText();
    }
  }

  void _updateText() {
    _controller.text = widget.password.isNotEmpty
        ? widget.password
        : (widget.isSet ? '••••••••' : '-');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    final canReveal = widget.password.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 16, top: 13, bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 2, height: 52, color: widget.accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    widget.label,
                    style: TextStyle(
                        fontSize: 14, color: textColor?.withOpacity(0.5)),
                    maxLines: 1,
                  ),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        readOnly: true,
                        obscureText: canReveal && !_visible,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 14, bottom: 10),
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Tooltip(
                      message: widget.configureLabel,
                      child: InkWell(
                        onTap: widget.onConfigure,
                        onHover: (value) =>
                            setState(() => _configureHover = value),
                        child: Icon(Icons.settings_outlined,
                                size: 22,
                                color: widget.onConfigure != null &&
                                        _configureHover
                                    ? textColor
                                    : const Color(0xFFDDDDDD))
                            .paddingOnly(right: 8, top: 4),
                      ),
                    ),
                    Tooltip(
                      message: canReveal
                          ? (_visible ? widget.hideLabel : widget.showLabel)
                          : widget.unavailableLabel,
                      child: InkWell(
                        onTap: canReveal
                            ? () => setState(() => _visible = !_visible)
                            : null,
                        onHover: (value) => setState(() => _eyeHover = value),
                        child: Icon(
                                _visible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 22,
                                color: canReveal && _eyeHover
                                    ? textColor
                                    : const Color(0xFFDDDDDD))
                            .paddingOnly(right: 8, top: 4),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
