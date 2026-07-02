import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Ядрои майдони матн дар асоси `EditableText`-и хом (БЕ контейнер).
///
/// Чаро на `TextField`: Flutter дар `TextField`/`TextFormField` ботинан
/// `backgroundCursorColor: CupertinoColors.inactiveGray` (хокистаранг) мегузорад,
/// ки дар баъзе дастгоҳҳои MIUI/Xiaomi ҳамчун ФОНИ хокистаранги майдон рендер мешавад.
/// Дар ин ҷо мо онро ба `Colors.transparent` мегузорем — пас ҳеҷ хокистарангӣ нест.
///
/// Ин виджет контейнер намекашад — онро дарунӣ (масалан дар `DarkTextField` ё
/// дар search-bar-и худсохт) истифода баред.
class SafeInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final Color textColor;
  final Color hintColor;
  final Color cursorColor;
  final double fontSize;

  const SafeInput({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.obscure = false,
    this.keyboardType,
    this.formatters,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textColor = Colors.white,
    this.hintColor = AppColors.textMuted,
    this.cursorColor = AppColors.primary,
    this.fontSize = 15,
  });

  @override
  State<SafeInput> createState() => _SafeInputState();
}

class _SafeInputState extends State<SafeInput> {
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _internalFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines != 1;
    final empty = widget.controller.text.isEmpty;
    // EditableText-и хом худ ба худ фокус намегирад — бо GestureDetector
    // ламскунӣ фокус мегирем, то дар ҳама ҷо клавиатура кушода шавад.
    return GestureDetector(
      onTap: () {
        if (!_focus.hasFocus) _focus.requestFocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
        children: [
        if (empty)
          IgnorePointer(
            child: Text(
              widget.hint,
              maxLines: multiline ? null : 1,
              overflow: multiline ? null : TextOverflow.ellipsis,
              style: TextStyle(color: widget.hintColor, fontSize: widget.fontSize),
            ),
          ),
        EditableText(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType ??
              (multiline ? TextInputType.multiline : TextInputType.text),
          inputFormatters: widget.formatters,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          autocorrect: false,
          enableSuggestions: false,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          style: TextStyle(color: widget.textColor, fontSize: widget.fontSize),
          cursorColor: widget.cursorColor,
          // ✅ ин калидист — ягон фони хокистаранг намекашад
          backgroundCursorColor: Colors.transparent,
          selectionColor: AppColors.primary.withValues(alpha: 0.30),
          selectionControls: materialTextSelectionControls,
          cursorOpacityAnimates: false,
        ),
        ],
      ),
    );
  }
}
