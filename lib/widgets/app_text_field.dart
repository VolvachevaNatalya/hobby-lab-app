import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final bool isRequired;

  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.isRequired = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus;
  bool _obscure = true;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
    if (widget.isRequired && widget.controller != null) {
      widget.controller!.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.isRequired && widget.controller != null) {
      widget.controller!.removeListener(_onControllerChanged);
    }
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final isEmpty = widget.controller?.text.trim().isEmpty ?? true;
    final showStar = widget.isRequired && isEmpty;

    final borderColor = hasError
        ? const Color(0xFFEF4444)
        : (_focused ? AppColors.purple : AppColors.divider);
    final borderWidth = hasError ? 1.5 : (_focused ? 1.5 : 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: _focused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            focusNode: _focus,
            controller: widget.controller,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontSize: 15),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 15),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  widget.prefixIcon,
                  color: _focused ? AppColors.purple : AppColors.textMuted,
                  size: 20,
                ),
              ),
              // Red * suffix when required and empty
              suffix: showStar
                  ? const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }
}
