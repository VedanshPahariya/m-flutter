import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/format.dart';
import 'ticket_repository.dart';

/// Closing needs the customer's OTP, proving the fix worked for them:
/// `otp_generate` → `otp_verify` → `close`.
class TicketCloseScreen extends StatefulWidget {
  const TicketCloseScreen({super.key, required this.ticket});

  final Ticket ticket;

  @override
  State<TicketCloseScreen> createState() => _TicketCloseScreenState();
}

class _TicketCloseScreenState extends State<TicketCloseScreen> {
  final _otp = TextEditingController();
  final _resolution = TextEditingController();
  bool _sent = false;
  bool _verified = false;
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  TicketRepository get _repo => TicketRepository(context.api);

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _resolution.dispose();
    super.dispose();
  }

  bool get _ready =>
      _otp.text.length >= 4 && _resolution.text.trim().length > 3;

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await _repo.sendClosureOtp(widget.ticket.id);
      if (!mounted) return;
      setState(() => _sent = true);
      _timer?.cancel();
      _cooldown = 45;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _cooldown--);
        if (_cooldown <= 0) t.cancel();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyAndClose() async {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_verified) {
        await _repo.verifyClosureOtp(cid: widget.ticket.id, otp: _otp.text);
        _verified = true;
      }
      final message = await _repo.close(
        cid: widget.ticket.id,
        resolution: _resolution.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.ticket.code}: $message')),
      );
      Navigator.of(context).pop(true);
    } on TimeoutApiException {
      if (mounted) {
        setState(
          () => _error = 'No response from the server. The ticket may already be closed — go back and refresh before retrying.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final t = widget.ticket;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Close ticket'),
            Text(
              '${t.code} · ${t.customerName}',
              style: TextStyle(
                fontSize: 13,
                color: k.ink3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Step(
            number: 1,
            title: 'Send a code to the customer',
            done: _sent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.customerName}${t.contact.isNotEmpty ? ' · +91 ${maskPhone(t.contact)}' : ''}. '
                  'They read it back to you once they confirm the fix works.',
                  style: TextStyle(color: k.ink3),
                ),
                const SizedBox(height: 10),
                if (!_sent)
                  FilledButton.tonal(
                    onPressed: _busy ? null : _send,
                    child: const Text('Send OTP'),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.check, color: k.ok, size: 18),
                      const SizedBox(width: 6),
                      Text('Sent', style: TextStyle(color: k.ok)),
                      const Spacer(),
                      TextButton(
                        onPressed: _busy || _cooldown > 0 ? null : _send,
                        child: Text(
                          _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _Step(
            number: 2,
            title: 'Enter the customer’s code',
            done: _verified,
            child: TextField(
              controller: _otp,
              enabled: _sent && !_busy && !_verified,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '••••••'),
            ),
          ),
          _Step(
            number: 3,
            title: 'Resolution',
            done: false,
            child: TextField(
              controller: _resolution,
              enabled: !_busy,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'What fixed it? Shown to the customer.',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: k.danger)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy || !_ready ? null : _verifyAndClose,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_verified ? 'Close ticket' : 'Verify & close ticket'),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.child,
    required this.done,
  });

  final int number;
  final String title;
  final Widget child;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done ? k.ok : k.accentContainer,
            child: done
                ? Icon(Icons.check, size: 16, color: k.raised)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: k.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
