import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../repositories/auth_repository.dart';
import '../../utils/auth_validators.dart';

import '../../widgets/app_logo_widget.dart';

enum ForgotPasswordStatus {
  initial,
  success,
  googleUser,
  userNotFound,
  tooManyRequests,
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  ForgotPasswordStatus _status = ForgotPasswordStatus.initial;
  String? _inlineEmailError;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    setState(() {
      _inlineEmailError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    debugPrint("--------------------------------------------------");
    debugPrint(
      "FORGOT PASSWORD: Attempting to send reset link to email: '$email'",
    );
    debugPrint("--------------------------------------------------");

    try {
      // Execute reset password call via Firebase Auth
      await ref.read(authRepositoryProvider).resetPassword(email);
      debugPrint("FORGOT PASSWORD SUCCESS: Reset link email sent to '$email'");

      if (mounted) {
        setState(() {
          _status = ForgotPasswordStatus.success;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "FORGOT PASSWORD ERROR [FirebaseAuthException]: code='${e.code}', message='${e.message}'",
      );
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        setState(() => _status = ForgotPasswordStatus.userNotFound);
      } else if (e.code == 'invalid-email') {
        setState(
          () => _inlineEmailError = e.message ?? 'Invalid email address format',
        );
      } else if (e.code == 'too-many-requests') {
        setState(() => _status = ForgotPasswordStatus.tooManyRequests);
      } else if (e.code == 'account-exists-with-different-credential') {
        setState(() => _status = ForgotPasswordStatus.googleUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Failed to send reset link. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      debugPrint("FORGOT PASSWORD UNEXPECTED ERROR: $e\n$st");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appRootBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.appRootBg, context.appSurfaceAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxFormWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: _buildCardContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    switch (_status) {
      case ForgotPasswordStatus.success:
        return _buildSuccessView(context);
      case ForgotPasswordStatus.googleUser:
        return _buildGoogleUserView(context);
      case ForgotPasswordStatus.userNotFound:
        return _buildUserNotFoundView(context);
      case ForgotPasswordStatus.tooManyRequests:
        return _buildTooManyRequestsView(context);
      case ForgotPasswordStatus.initial:
        return _buildFormView(context);
    }
  }

  Widget _buildHeader() {
    return Column(
      children: const [AppLogoWidget(size: 48), SizedBox(height: 24)],
    );
  }

  Widget _buildFormView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Text(
            'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter your email and we'll send you a reset link",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.appTextSecondary),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: context.appTextMuted),
              prefixIcon: const Icon(
                Icons.mail_outline,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: context.appSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.appBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorText: _inlineEmailError,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isLoading) _sendResetLink();
            },
            validator: AuthValidators.validateEmail,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _sendResetLink,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: _isLoading ? null : () => context.go('/login'),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final email = _emailController.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          child: const Icon(
            Icons.mark_email_read,
            color: AppColors.success,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Check your inbox!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a password reset link to\n$email",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => context.go('/login'),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleUserView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          child: const Icon(
            Icons.g_mobiledata,
            color: AppColors.warning,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Google Account Detected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "This email is linked to a Google account. Please use the 'Continue with Google' button to sign in. You don't need a password.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: context.appSurfaceAlt,
              foregroundColor: context.appTextPrimary,
              side: BorderSide(color: context.appBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.go('/login'),
            icon: const Icon(
              Icons.g_mobiledata,
              size: 28,
              color: Colors.redAccent,
            ),
            label: Text(
              'Back to Login (Google Sign-In)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserNotFoundView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          child: const Icon(Icons.person_off, color: AppColors.error, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          'Account Not Found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'No account found with this email. Would you like to create one?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => context.go('/signup'),
            child: const Text(
              'Create Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              setState(() => _status = ForgotPasswordStatus.initial),
          child: const Text(
            'Try Another Email',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTooManyRequestsView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          child: const Icon(
            Icons.hourglass_empty,
            color: AppColors.warning,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Too Many Attempts',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Too many attempts. Please try again later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.appTextSecondary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => context.go('/login'),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
