import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final GymApi api;
  final AuthSession session;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.api.changePassword(
        session: widget.session,
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Something went wrong while changing your password.';
      });
    } finally {
      if (mounted && _submitting) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Change password')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Keep your account secure',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your current password, then choose a new one.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 20),
                AppSurface(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PasswordField(
                          controller: _currentPasswordController,
                          label: 'Current password',
                          visible: _showCurrentPassword,
                          onVisibilityChanged: () {
                            setState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _PasswordField(
                          controller: _newPasswordController,
                          label: 'New password',
                          visible: _showNewPassword,
                          onVisibilityChanged: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                          onChanged: (_) {
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _formKey.currentState?.validate();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a new password';
                            }
                            if (value.trim().isEmpty) {
                              return 'New password cannot be blank';
                            }
                            if (value != value.trim()) {
                              return 'New password cannot start or end with spaces';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _PasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm new password',
                          visible: _showConfirmPassword,
                          onVisibilityChanged: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'The new passwords do not match';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            _submit();
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text('Change password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onVisibilityChanged,
    required this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onVisibilityChanged;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: onFieldSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: visible ? 'Hide password' : 'Show password',
          onPressed: onVisibilityChanged,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
