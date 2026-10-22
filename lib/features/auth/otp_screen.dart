import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/auth_controller.dart';

/// Passwordless customer sign-in: `m/auth/sendOTP` then `m/auth/verifyOTP`.
/// The server enforces expiry, resend cooldown and attempt limits; the
/// 30-second resend timer here only prevents accidental double sends.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.initialIdentifier = ''});

  final String initialIdentifier;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final _identifier = TextEditingController(
    text: widget.initialIdentifier,
  );
  final _code = TextEditingController();
  OtpChallenge? _challenge;
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _identifier.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    if (_identifier.text.trim().isEmpty) {
      setState(() => _error = 'Enter your mobile number or customer ID');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await AppScope.of(context).auth
          .requestOtp(_identifier.text);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _code.clear();
      });
      _startCooldown();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(challenge.message)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final challenge = _challenge;
    if (challenge == null || _code.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).auth
          .verifyOtp(pendingToken: challenge.pendingToken, otp: _code.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final sent = _challenge != null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sent ? 'Enter the 6-digit code' : 'Sign in with a code',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sent
                    ? 'We sent a code to the mobile number registered for ${_identifier.text.trim()}.'
                    : 'For customer accounts. We’ll send a one-time code to your registered mobile number.',
                style: TextStyle(color: k.ink3),
              ),
              const SizedBox(height: 24),
              if (!sent)
                TextField(
                  controller: _identifier,
                  enabled: !_busy,
                  autofocus: _identifier.text.isEmpty,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    labelText: 'Mobile number or customer ID',
                  ),
                )
              else
                TextField(
                  controller: _code,
                  enabled: !_busy,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (v.length == 6) _verify();
                  },
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: k.danger)),
              ],
              const SizedBox(height: 20),
              if (!sent)
                FilledButton(
                  onPressed: _busy ? null : _send,
                  child: _busy ? const _Spinner() : const Text('Send code'),
                )
              else ...[
                FilledButton(
                  onPressed: _busy || _code.text.length != 6 ? null : _verify,
                  child: _busy ? const _Spinner() : const Text('Verify'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy || _cooldown > 0 ? null : _send,
                  child: Text(
                    _cooldown > 0
                        ? 'Resend in 0:${_cooldown.toString().padLeft(2, '0')}'
                        : 'Resend code',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(strokeWidth: 2.5),
  );
}
