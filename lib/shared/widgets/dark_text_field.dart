import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Майдони матни 100% худсохт дар асоси EditableText-и хом.
///
/// Чаро на TextField: TextField-и Flutter ботинан
/// `backgroundCursorColor: CupertinoColors.inactiveGray` (хокистаранг)
/// мегузорад, ки дар баъзе дастгоҳҳои MIUI ҳамчун ФОНИ майдон рендер мешавад.
/// Дар ин ҷо мо онро ба `Colors.transparent` мегузорем — пас ҳеҷ хокистарангӣ нест.
class DarkTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const DarkTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.formatters,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<DarkTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final empty = widget.controller.text.isEmpty;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focused ? AppColors.primary : const Color(0xFF2A2A3E),
            width: focused ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Icon(widget.icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(alignment: Alignment.centerLeft, children: [
              if (empty)
                IgnorePointer(
                  child: Text(widget.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
                ),
              EditableText(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.formatters,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: AppColors.primary,
                // ✅ ин калидист — ягон фони хокистаранг намекашад
                backgroundCursorColor: Colors.transparent,
                selectionColor: AppColors.primary.withValues(alpha: 0.30),
                selectionControls: materialTextSelectionControls,
                cursorOpacityAnimates: false,
              ),
            ]),
          ),
          if (widget.suffix != null) widget.suffix!,
        ]),
      ),
    );
  }
}
