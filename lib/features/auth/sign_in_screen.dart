import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/session.dart';
import '../splash/app_logo.dart';
import 'otp_screen.dart';
import 'seeker_register_screen.dart';

/// Unauthenticated area with its own navigator, so the back button moves
/// between sign-in, OTP and registration without leaving the app.
class SignInFlow extends StatelessWidget {
  const SignInFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  AccountKind _kind = AccountKind.staff;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppScope.of(context).auth.lastIdentifier().then((value) {
      if (mounted && value != null && _identifier.text.isEmpty) {
        _identifier.text = value;
      }
    });
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _identifierLabel => switch (_kind) {
    AccountKind.staff => 'Email',
    AccountKind.customer => 'Mobile number or customer ID',
    AccountKind.seeker => 'Email',
  };

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = AppScope.of(context).auth;
    setState(() {
      _busy = true;
      _error = null;
    });
    auth.clearNotice();
    try {
      if (_kind == AccountKind.seeker) {
        await auth.loginSeeker(
          email: _identifier.text,
          password: _password.text,
        );
      } else {
        await auth.login(
          identifier: _identifier.text,
          password: _password.text,
          kind: _kind,
        );
      }
      // AuthGate swaps this screen out on success.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotDialog(
        initial: _identifier.text.contains('@') ? _identifier.text : '',
      ),
    );
    if (email == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await AppScope.of(context).auth
          .forgotPassword(email: email, kind: _kind);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final notice = AppScope.of(context).auth.notice;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppConfig.appName,
                              style: context.text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Sign in',
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your account type to continue.',
                        style: TextStyle(color: k.ink3),
                      ),
                      if (notice != null) ...[
                        const SizedBox(height: 16),
                        _Banner(icon: Icons.schedule, text: notice),
                      ],
                      const SizedBox(height: 20),
                      SegmentedButton<AccountKind>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: AccountKind.staff,
                            label: Text('Staff'),
                          ),
                          ButtonSegment(
                            value: AccountKind.customer,
                            label: Text('Customer'),
                          ),
                          ButtonSegment(
                            value: AccountKind.seeker,
                            label: Text('Job seeker'),
                          ),
                        ],
                        selected: {_kind},
                        onSelectionChanged: _busy
                            ? null
                            : (s) => setState(() {
                                _kind = s.first;
                                _error = null;
                              }),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _identifier,
                        enabled: !_busy,
                        keyboardType: _kind == AccountKind.customer
                            ? TextInputType.text
                            : TextInputType.emailAddress,
                        autofillHints: [
                          _kind == AccountKind.customer
                              ? AutofillHints.telephoneNumber
                              : AutofillHints.email,
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _identifierLabel,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Enter your ${_identifierLabel.toLowerCase()}';
                          }
                          if (_kind == AccountKind.seeker &&
                              !value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your password'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error, size: 18, color: k.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: k.danger),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_kind != AccountKind.customer)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _busy ? null : _forgot,
                            child: const Text('Forgot password?'),
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      if (_kind == AccountKind.customer) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OtpScreen(
                                      initialIdentifier: _identifier.text,
                                    ),
                                  ),
                                ),
                          child: const Text('Sign in with a one-time code'),
                        ),
                      ],
                      if (_kind == AccountKind.seeker) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SeekerRegisterScreen(),
                                  ),
                                ),
                          child: const Text('Create a job seeker account'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: k.warnContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: k.warnInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: k.warnInk)),
          ),
        ],
      ),
    );
  }
}

class _ForgotDialog extends StatefulWidget {
  const _ForgotDialog({required this.initial});

  final String initial;

  @override
  State<_ForgotDialog> createState() => _ForgotDialogState();
}

class _ForgotDialogState extends State<_ForgotDialog> {
  late final _email = TextEditingController(text: widget.initial);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Account email'),
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_key.currentState!.validate()) {
              Navigator.pop(context, _email.text.trim());
            }
          },
          child: const Text('Send link'),
        ),
      ],
    );
  }
}
