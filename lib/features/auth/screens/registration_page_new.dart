import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:sehatmakaan/data/providers/registration_provider.dart';
import 'package:sehatmakaan/core/constants/constants.dart';

// ✅ CRITICAL FIX: Convert to StatefulWidget to prevent provider recreation
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // ✅ Provider instance persists across rebuilds (won't recreate on keyboard open)
  late final RegistrationProvider _registrationProvider;

  @override
  void initState() {
    super.initState();
    _registrationProvider = RegistrationProvider();
    debugPrint('✅ RegistrationProvider initialized once in initState');
  }

  @override
  void dispose() {
    _registrationProvider.dispose(); // ✅ Proper cleanup to avoid memory leaks
    debugPrint('✅ RegistrationProvider disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use .value() with existing instance instead of create:
    // This prevents rebuilds from creating new provider instances
    return ChangeNotifierProvider.value(
      value: _registrationProvider,
      child: _RegistrationPageContent(provider: _registrationProvider),
    );
  }
}

class _RegistrationPageContent extends StatefulWidget {
  final RegistrationProvider provider;

  const _RegistrationPageContent({required this.provider});

  @override
  State<_RegistrationPageContent> createState() =>
      _RegistrationPageContentState();
}

class _RegistrationPageContentState extends State<_RegistrationPageContent> {
  // ✅ FormKey persists in State, won't recreate on keyboard open
  late final GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    debugPrint('✅ FormKey initialized in State');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      // ✅ Optional: Prevent scaffold resizing on keyboard (test if needed)
      // resizeToAvoidBottomInset: false,
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
              _buildFormContainer(context, widget.provider, formKey),
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
class _FullNameField extends StatefulWidget {
  final RegistrationProvider provider;

  const _FullNameField({required this.provider});

  @override
  State<_FullNameField> createState() => _FullNameFieldState();
}

class _FullNameFieldState extends State<_FullNameField> {
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
          controller: widget.provider.fullNameController,
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
class _EmailFieldWithOtp extends StatefulWidget {
  final RegistrationProvider provider;
  const _EmailFieldWithOtp({required this.provider});

  @override
  State<_EmailFieldWithOtp> createState() => _EmailFieldWithOtpState();
}

class _EmailFieldWithOtpState extends State<_EmailFieldWithOtp> {
  late FocusNode emailFocusNode;
  late FocusNode otpFocusNode;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize FocusNodes in initState - they persist across rebuilds
    emailFocusNode = FocusNode();
    otpFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // ✅ Dispose FocusNodes to prevent memory leaks
    emailFocusNode.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

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
                focusNode: emailFocusNode,
                controller: widget.provider.emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: context.select<RegistrationProvider, bool>(
                  (p) => !p.isEmailVerified,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('Enter your email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Selector<RegistrationProvider, int>(
              selector: (_, p) => p.resendCountdown,
              builder: (context, countdown, _) {
                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed:
                        (widget.provider.isEmailVerified ||
                            widget.provider.isSendingEmailOtp ||
                            countdown > 0)
                        ? null
                        : () async {
                            final error = await widget.provider.sendEmailOtp();
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
                                // ✅ Auto-focus OTP field after sending OTP
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    otpFocusNode.requestFocus();
                                  },
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
                    child: widget.provider.isSendingEmailOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.provider.isEmailVerified
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
                        focusNode: otpFocusNode,
                        controller: widget.provider.emailOtpController,
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _inputDecoration('Enter 6-digit OTP'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.provider.emailOtpController,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: value.text.length == 6
                                ? () {
                                    final error = widget.provider
                                        .verifyEmailOtp();
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
                                      // ✅ Auto-focus phone field after email verification
                                      Future.delayed(
                                        const Duration(milliseconds: 500),
                                        () {
                                          _PhoneFieldWithOtpState.focusPhoneField();
                                        },
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
class _PhoneFieldWithOtp extends StatefulWidget {
  final RegistrationProvider provider;

  const _PhoneFieldWithOtp({required this.provider});

  @override
  State<_PhoneFieldWithOtp> createState() => _PhoneFieldWithOtpState();
}

class _PhoneFieldWithOtpState extends State<_PhoneFieldWithOtp> {
  late FocusNode phoneFocusNode;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize FocusNode in initState - persists across rebuilds
    phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // ✅ Dispose FocusNode to prevent memory leaks
    phoneFocusNode.dispose();
    super.dispose();
  }

  // ✅ Static instance to access from other widgets
  static _PhoneFieldWithOtpState? _instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _instance = this;
  }

  // ✅ Public static method to focus phone field from anywhere
  static void focusPhoneField() {
    _instance?.phoneFocusNode.requestFocus();
  }

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
                focusNode: phoneFocusNode,
                controller: widget.provider.phoneController,
                keyboardType: TextInputType.phone,
                enabled: context.select<RegistrationProvider, bool>(
                  (p) => !p.isPhoneVerified,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('+92 300 1234567').copyWith(
                  suffixIcon:
                      context.select<RegistrationProvider, bool>(
                        (p) => p.isPhoneVerified,
                      )
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
class _PasswordField extends StatefulWidget {
  final RegistrationProvider provider;
  const _PasswordField({required this.provider});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
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
              controller: widget.provider.passwordController,
              obscureText: obscure, // ✅ Updates dynamically
              decoration: _inputDecoration('Minimum 6 characters').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF006876),
                  ),
                  onPressed: () => widget.provider
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

class _ConfirmPasswordField extends StatefulWidget {
  final RegistrationProvider provider;
  const _ConfirmPasswordField({required this.provider});

  @override
  State<_ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<_ConfirmPasswordField> {
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
              controller: widget.provider.confirmPasswordController,
              obscureText: obscure, // ✅ Updates dynamically
              decoration: _inputDecoration('Re-enter password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF006876),
                  ),
                  onPressed: () =>
                      widget.provider.toggleConfirmPasswordVisibility(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != widget.provider.passwordController.text) {
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

class _AgeField extends StatefulWidget {
  final RegistrationProvider provider;

  const _AgeField({required this.provider});

  @override
  State<_AgeField> createState() => _AgeFieldState();
}

class _AgeFieldState extends State<_AgeField> {
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
          controller: widget.provider.ageController,
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

class _GenderField extends StatefulWidget {
  final RegistrationProvider provider;

  const _GenderField({required this.provider});

  @override
  State<_GenderField> createState() => _GenderFieldState();
}

class _GenderFieldState extends State<_GenderField> {
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
          initialValue: widget.provider.selectedGender,
          decoration: _inputDecoration('Select Gender'),
          items: AppConstants.genders.map((gender) {
            return DropdownMenuItem(
              value: gender['value'],
              child: Text(gender['label']!),
            );
          }).toList(),
          onChanged: widget.provider.setGender,
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

class _YearsExpField extends StatefulWidget {
  final RegistrationProvider provider;

  const _YearsExpField({required this.provider});

  @override
  State<_YearsExpField> createState() => _YearsExpFieldState();
}

class _YearsExpFieldState extends State<_YearsExpField> {
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
          controller: widget.provider.yearsExpController,
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

class _SpecialtyField extends StatefulWidget {
  final RegistrationProvider provider;

  const _SpecialtyField({required this.provider});

  @override
  State<_SpecialtyField> createState() => _SpecialtyFieldState();
}

class _SpecialtyFieldState extends State<_SpecialtyField> {
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
          initialValue: widget.provider.selectedSpecialty,
          decoration: _inputDecoration('Select Your Specialty'),
          items: AppConstants.specialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty['value'],
              child: Text(specialty['label']!),
            );
          }).toList(),
          onChanged: widget.provider.setSpecialty,
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

class _PMDCField extends StatefulWidget {
  final RegistrationProvider provider;

  const _PMDCField({required this.provider});

  @override
  State<_PMDCField> createState() => _PMDCFieldState();
}

class _PMDCFieldState extends State<_PMDCField> {
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
          controller: widget.provider.pmdcController,
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

class _CNICField extends StatefulWidget {
  final RegistrationProvider provider;

  const _CNICField({required this.provider});

  @override
  State<_CNICField> createState() => _CNICFieldState();
}

class _CNICFieldState extends State<_CNICField> {
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
          controller: widget.provider.cnicController,
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

class _SubmitButton extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final RegistrationProvider provider;

  const _SubmitButton({required this.formKey, required this.provider});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  @override
  Widget build(BuildContext context) {
    // ✅ Listen ONLY to isLoading state change
    final isLoading = context.select<RegistrationProvider, bool>(
      (p) => p.isLoading,
    );

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              if (!widget.formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fix all errors before submitting'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final error = await widget.provider.submitRegistration();
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
      child: isLoading
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
// ✅ Constant InputDecoration styling to avoid rebuilds
const _standardBorderRadius = BorderRadius.all(Radius.circular(8));
const _standardContentPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 16,
);
const _fillColor = Color(0xFFE6F7F9);
const _disabledFillColor = Color(0xFFE0E0E0);
const _primaryColor = Color(0xFFFF6B35);
const _errorColor = Colors.red;

InputDecoration _inputDecoration(
  String hint, {
  bool hasError = false,
  bool isDisabled = false,
}) {
  // ✅ Reuse common borders to reduce object creation
  final errorBorder = OutlineInputBorder(
    borderRadius: _standardBorderRadius,
    borderSide: const BorderSide(color: _errorColor, width: 1),
  );

  final normalBorder = const OutlineInputBorder(
    borderRadius: _standardBorderRadius,
    borderSide: BorderSide.none,
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: _standardBorderRadius,
    borderSide: BorderSide(
      color: hasError ? _errorColor : _primaryColor,
      width: 2,
    ),
  );

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: isDisabled ? _disabledFillColor : _fillColor,
    border: hasError ? errorBorder : normalBorder,
    enabledBorder: hasError ? errorBorder : normalBorder,
    focusedBorder: focusedBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: _standardBorderRadius,
      borderSide: const BorderSide(color: _errorColor, width: 2),
    ),
    contentPadding: _standardContentPadding,
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
