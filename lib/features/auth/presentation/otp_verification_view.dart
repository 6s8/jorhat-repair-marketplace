import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

/// Presentation widget for verifying 4-6 digit SMS OTP.
class OtpVerificationView extends ConsumerStatefulWidget {
  const OtpVerificationView({super.key});

  @override
  ConsumerState<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends ConsumerState<OtpVerificationView> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  void _handleVerify() {
    if (_formKey.currentState!.validate()) {
      final token = _otpController.text.trim();
      ref.read(authControllerProvider.notifier).verifyOtp(token);
    }
  }

  void _handleResend() {
    final phone = ref.read(authControllerProvider).phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      ref.read(authControllerProvider.notifier).sendOtp(phone);
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final phone = uiState.phoneNumber ?? '';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top header showing phone number being verified
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OTP sent to mobile',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                      Text(
                        '+91 $phone',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: uiState.isLoading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .resetPhoneInput(),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Enter Verification Code (OTP)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !uiState.isLoading,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 8.0,
            ),
            decoration: InputDecoration(
              hintText: '• • • • • •',
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 4) {
                return 'Please enter valid OTP code';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Resend OTP Countdown / Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Didn\'t receive OTP?',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              _resendCountdown > 0
                  ? Text(
                      'Resend in ${_resendCountdown}s',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    )
                  : TextButton(
                      onPressed: uiState.isLoading ? null : _handleResend,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),

          if (uiState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uiState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: uiState.isLoading ? null : _handleVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.text,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: uiState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.text,
                      ),
                    )
                  : const Text(
                      'Verify & Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
