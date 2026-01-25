import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/data/providers/registration_provider.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationProvider(),
      child: const _RegistrationPageContent(),
    );
  }
}

class _RegistrationPageContent extends StatelessWidget {
  const _RegistrationPageContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006876)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Registration',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            color: const Color(0xFF006876),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            children: [
              _buildHeader(context),
              SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5,
              ),
              _buildFormContainer(context, provider, formKey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: ResponsiveHelper.isMobile(context) ? 60 : 80,
          height: ResponsiveHelper.isMobile(context) ? 60 : 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person_add,
            size: ResponsiveHelper.isMobile(context) ? 30 : 40,
            color: Colors.white,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
        Text(
          'Register Your Practice',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006876),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.3),
        Text(
          'Complete your professional registration to access our platform',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: const Color(0xFF006876).withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormContainer(
    BuildContext context,
    RegistrationProvider provider,
    GlobalKey<FormState> formKey,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FullNameField(provider: provider),
            const SizedBox(height: 24),
            _EmailFieldWithOtp(provider: provider),
            const SizedBox(height: 24),
            _PhoneFieldWithOtp(provider: provider),
            const SizedBox(height: 24),
            _PasswordField(provider: provider),
            const SizedBox(height: 24),
            _ConfirmPasswordField(provider: provider),
            const SizedBox(height: 24),
            _AgeField(provider: provider),
            const SizedBox(height: 24),
            _GenderField(provider: provider),
            const SizedBox(height: 24),
            _YearsExpField(provider: provider),
            const SizedBox(height: 24),
            _SpecialtyField(provider: provider),
            const SizedBox(height: 24),
            _PMDCField(provider: provider),
            const SizedBox(height: 24),
            _CNICField(provider: provider),
            const SizedBox(height: 32),
            _SubmitButton(formKey: formKey, provider: provider),
          ],
        ),
      ),
    );
  }
}

// Full Name Field
class _FullNameField extends StatelessWidget {
  final RegistrationProvider provider;

  const _FullNameField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.fullNameController,
          decoration: _inputDecoration('Enter your full name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// Email Field with OTP Verification
class _EmailFieldWithOtp extends StatelessWidget {
  final RegistrationProvider provider;
  const _EmailFieldWithOtp({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: provider.emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !provider.isEmailVerified,
                decoration: _inputDecoration('Enter your email'),
              ),
            ),
            const SizedBox(width: 8),
            // ✅ Only the button rebuilds with the timer
            Selector<RegistrationProvider, int>(
              selector: (_, p) => p.resendCountdown,
              builder: (context, countdown, _) {
                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed:
                        (provider.isEmailVerified ||
                            provider.isSendingEmailOtp ||
                            countdown > 0)
                        ? null
                        : () async {
                            final error = await provider.sendEmailOtp();
                            if (context.mounted) {
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP sent to your email'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: provider.isSendingEmailOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            provider.isEmailVerified
                                ? 'Verified'
                                : (countdown > 0 ? '${countdown}s' : 'Verify'),
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
        // ✅ OTP field visibility logic
        Selector<RegistrationProvider, bool>(
          selector: (_, p) => p.isEmailVerified,
          builder: (context, isVerified, _) {
            if (isVerified) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey(
                          'otp_field_stable',
                        ), // ✅ Stable identity
                        controller: provider.emailOtpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _inputDecoration('Enter 6-digit OTP'),
                        // ❌ REMOVED markNeedsBuild() to stop blinking
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ This listens to typing without rebuilding the whole field
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: provider.emailOtpController,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: value.text.length == 6
                                ? () {
                                    final error = provider.verifyEmailOtp();
                                    if (error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Email verified successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90D26D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Phone Field with OTP Verification
class _PhoneFieldWithOtp extends StatelessWidget {
  final RegistrationProvider provider;

  const _PhoneFieldWithOtp({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: provider.phoneController,
                keyboardType: TextInputType.phone,
                enabled: !provider.isPhoneVerified,
                decoration: _inputDecoration('+92 300 1234567').copyWith(
                  suffixIcon: provider.isPhoneVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');
                  final phoneRegex = RegExp(r'^(\+92|0)?3[0-9]{9}$');
                  if (!phoneRegex.hasMatch(cleanNumber)) {
                    return 'Enter valid Pakistani phone (03xxxxxxxxx)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Other fields remain similar but use provider
class _PasswordField extends StatelessWidget {
  final RegistrationProvider provider;
  const _PasswordField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Selector<RegistrationProvider, bool>(
      selector: (_, p) => p.obscurePassword, // Sirf obscurePassword ko dekho
      builder: (context, obscure, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password *',
              style: TextStyle(
                color: Color(0xFF006876),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: provider.passwordController,
              obscureText: obscure, // ✅ Updates dynamically
              decoration: _inputDecoration('Minimum 6 characters').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF006876),
                  ),
                  onPressed: () => provider
                      .togglePasswordVisibility(), // ✅ Now triggers rebuild
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }
}

class _ConfirmPasswordField extends StatelessWidget {
  final RegistrationProvider provider;
  const _ConfirmPasswordField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Selector<RegistrationProvider, bool>(
      selector: (_, p) =>
          p.obscureConfirmPassword, // Sirf confirm wali state dekho
      builder: (context, obscure, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Password *',
              style: TextStyle(
                color: Color(0xFF006876),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: provider.confirmPasswordController,
              obscureText: obscure, // ✅ Updates dynamically
              decoration: _inputDecoration('Re-enter password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF006876),
                  ),
                  onPressed: () => provider.toggleConfirmPasswordVisibility(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != provider.passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }
}

class _AgeField extends StatelessWidget {
  final RegistrationProvider provider;

  const _AgeField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Enter your age'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value);
            if (age == null || age < 18 || age > 100) {
              return 'Enter a valid age (18-100)';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _GenderField extends StatelessWidget {
  final RegistrationProvider provider;

  const _GenderField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: provider.selectedGender,
          decoration: _inputDecoration('Select Gender'),
          items: AppConstants.genders.map((gender) {
            return DropdownMenuItem(
              value: gender['value'],
              child: Text(gender['label']!),
            );
          }).toList(),
          onChanged: provider.setGender,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Gender is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _YearsExpField extends StatelessWidget {
  final RegistrationProvider provider;

  const _YearsExpField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Years of Experience *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.yearsExpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Enter years'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Experience is required';
            }
            final years = int.tryParse(value);
            if (years == null || years < 0) {
              return 'Enter valid years';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SpecialtyField extends StatelessWidget {
  final RegistrationProvider provider;

  const _SpecialtyField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialty *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: provider.selectedSpecialty,
          decoration: _inputDecoration('Select Your Specialty'),
          items: AppConstants.specialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty['value'],
              child: Text(specialty['label']!),
            );
          }).toList(),
          onChanged: provider.setSpecialty,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Specialty is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PMDCField extends StatelessWidget {
  final RegistrationProvider provider;

  const _PMDCField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PMDC Registration Number *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.pmdcController,
          decoration: _inputDecoration('PMDC-12345'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'PMDC number is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _CNICField extends StatelessWidget {
  final RegistrationProvider provider;

  const _CNICField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CNIC Number *',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.cnicController,
          keyboardType: TextInputType.number,
          maxLength: 15, // 13 digits + 2 dashes
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CnicInputFormatter(), // ✅ AUTO-FORMAT: xxxxx-xxxxxxx-x
          ],
          decoration: _inputDecoration('12345-6789012-3').copyWith(
            counterText: '', // Hide character counter
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'CNIC is required';
            }
            // Validate format: xxxxx-xxxxxxx-x
            if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value)) {
              return 'Invalid CNIC format (xxxxx-xxxxxxx-x)';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final RegistrationProvider provider;

  const _SubmitButton({required this.formKey, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: provider.isLoading
          ? null
          : () async {
              if (!formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fix all errors before submitting'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final error = await provider.submitRegistration();
              if (context.mounted) {
                if (error != null) {
                  // Check if account is suspended
                  if (error.startsWith('ACCOUNT_SUSPENDED:')) {
                    final reason = error.split(':')[1];
                    Navigator.pushReplacementNamed(
                      context,
                      '/account-suspended',
                      arguments: reason,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Registration Submitted! Awaiting admin approval.',
                      ),
                      backgroundColor: Color(0xFF90D26D),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Navigate to verification page
                  Navigator.pushReplacementNamed(context, '/verification');
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: provider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Submit Registration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}

// Input decoration helper
InputDecoration _inputDecoration(
  String hint, {
  bool hasError = false,
  bool isDisabled = false,
}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: isDisabled ? const Color(0xFFE0E0E0) : const Color(0xFFE6F7F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: hasError
          ? const BorderSide(color: Colors.red, width: 1)
          : BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: hasError
          ? const BorderSide(color: Colors.red, width: 1)
          : BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: hasError ? Colors.red : const Color(0xFFFF6B35),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

// ✅ CNIC Input Formatter: Auto-formats as xxxxx-xxxxxxx-x
class _CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    // Limit to 13 digits only
    if (text.length > 13) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Add dash after 5th digit
      if (i == 4 && text.length > 5) {
        buffer.write('-');
      }
      // Add dash after 12th digit
      if (i == 11 && text.length > 12) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
