import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import 'safe_input.dart';

/// Майдони матни 100% худсохт (контейнери торик + `SafeInput`).
///
/// `SafeInput` дар асоси `EditableText`-и хом аст ва
/// `backgroundCursorColor: Colors.transparent` мегузорад — пас дар MIUI
/// ягон фони хокистаранг рендер намешавад.
class DarkTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;

  const DarkTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.formatters,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<DarkTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final multiline = widget.maxLines != 1;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(minHeight: multiline ? 96 : 56),
        decoration: BoxDecoration(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focused ? AppColors.primary : context.pal.border,
            width: focused ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment:
              multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Padding(
                padding: EdgeInsets.only(top: multiline ? 6 : 0),
                child: Icon(widget.icon, color: context.pal.textMuted, size: 20),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SafeInput(
                controller: widget.controller,
                focusNode: _focus,
                hint: widget.hint,
                obscure: widget.obscure,
                keyboardType: widget.keyboardType,
                formatters: widget.formatters,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
              ),
            ),
            if (widget.suffix != null) widget.suffix!,
          ],
        ),
      ),
    );
  }
}
