import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
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
    this.suffixWidget,
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
  late final FocusNode _focus;
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _ctrl = widget.controller ?? TextEditingController();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator != null
          ? (_) => widget.validator!(_ctrl.text)
          : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                minHeight: widget.maxLines > 1 ? (widget.maxLines * 22.0 + 32) : 54,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: field.hasError
                      ? AppColors.error
                      : _focus.hasFocus
                          ? AppColors.primary
                          : AppColors.border,
                  width: _focus.hasFocus ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.prefixIcon != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 0, 0),
                      child: Icon(widget.prefixIcon,
                          color: _focus.hasFocus
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: EditableText(
                        controller: _ctrl,
                        focusNode: _focus,
                        obscureText: widget.obscure,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        maxLines: widget.obscure ? 1 : widget.maxLines,
                        minLines: 1,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        cursorColor: AppColors.primary,
                        backgroundCursorColor: Colors.grey,
                        onChanged: (v) {
                          widget.onChanged?.call(v);
                          field.didChange(v);
                        },
                      ),
                    ),
                  ),
                  if (widget.suffixWidget != null) widget.suffixWidget!,
                  const SizedBox(width: 4),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(field.errorText!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
            ],
          ],
        );
      },
    );
  }
}
