import 'package:flutter/material.dart';
import 'package:app_code/l10n/app_localizations.dart';

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.fieldKey,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofillHints,
    this.decoration,
  });

  final TextEditingController controller;
  final String? labelText;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final InputDecoration? decoration;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final baseDecoration = widget.decoration ?? const InputDecoration();
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      decoration: baseDecoration.copyWith(
        labelText: widget.labelText ?? l10n.passwordLabel,
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.showPasswordTooltip : l10n.hidePasswordTooltip,
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}
