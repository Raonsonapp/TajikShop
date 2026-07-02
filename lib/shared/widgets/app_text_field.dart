import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'safe_input.dart';

/// Майдони матн бо контейнери торик + валидатсия (барои `Form`).
///
/// Дар дохил `SafeInput` (EditableText-и хом) истифода мешавад, то дар MIUI
/// ягон фони хокистаранг набошад. Барои нигоҳ доштани `validator` бо `Form`,
/// `SafeInput` дар `FormField<String>` печонида шудааст.
class AppTextField extends StatefulWidget {
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixTap,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines != 1 && !widget.obscure;
    return FormField<String>(
      validator: (_) => widget.validator?.call(_controller.text),
      builder: (state) {
        final hasError = state.errorText != null;
        final focused = _focus.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _focus.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints:
                    BoxConstraints(minHeight: multiline ? 96 : 52),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError
                        ? AppColors.error
                        : focused
                            ? AppColors.primary
                            : AppColors.border,
                    width: hasError || focused ? 1.4 : 0.5,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  crossAxisAlignment: multiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Padding(
                        padding: EdgeInsets.only(top: multiline ? 6 : 0),
                        child: Icon(widget.prefixIcon,
                            color: AppColors.textMuted, size: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: SafeInput(
                        controller: _controller,
                        focusNode: _focus,
                        hint: widget.hint,
                        obscure: widget.obscure,
                        keyboardType: widget.keyboardType,
                        formatters: widget.inputFormatters,
                        maxLines: widget.obscure ? 1 : widget.maxLines,
                        onChanged: (v) {
                          widget.onChanged?.call(v);
                          if (hasError) state.didChange(v);
                        },
                      ),
                    ),
                    if (widget.suffixWidget != null)
                      widget.suffixWidget!
                    else if (widget.suffixIcon != null)
                      GestureDetector(
                        onTap: widget.onSuffixTap,
                        child: Icon(widget.suffixIcon,
                            color: AppColors.textMuted, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6),
                child: Text(state.errorText!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}
