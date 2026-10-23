import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/skeleton.dart';
import 'lead_repository.dart';

/// New enquiry: mobile first so duplicates are caught (`check_mobile`)
/// before anything else is typed, then `m/enquiry/add`.
class LeadNewScreen extends StatefulWidget {
  const LeadNewScreen({super.key});

  @override
  State<LeadNewScreen> createState() => _LeadNewScreenState();
}

class _LeadNewScreenState extends State<LeadNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _comment = TextEditingController();
  String _type = 'New licence';
  String _source = 'Walk-in';
  String? _branch;
  bool? _duplicate;
  bool _checking = false;
  bool _busy = false;
  String? _error;
  Timer? _debounce;
  int _checkGeneration = 0;

  static const _types = ['New licence', 'Upgrade', 'AMC renewal', 'Add-on'];
  static const _sources = [
    'Walk-in',
    'Call',
    'Website',
    'Referral',
    'WhatsApp',
  ];

  LeadRepository get _repo => LeadRepository(context.api);

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_mobile, _name, _address, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onMobileChanged(String value) {
    _debounce?.cancel();
    setState(() => _duplicate = null);
    if (value.length < 10) return;
    _debounce = Timer(const Duration(milliseconds: 500), () => _check(value));
  }

  Future<void> _check(String mobile) async {
    final generation = ++_checkGeneration;
    setState(() => _checking = true);
    try {
      final exists = await _repo.mobileExists(mobile);
      if (mounted && generation == _checkGeneration) {
        setState(() => _duplicate = exists);
      }
    } catch (_) {
      // The server checks again on save; a failed pre-check is not fatal.
    } finally {
      if (mounted && generation == _checkGeneration) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await _repo.add(
        name: _name.text,
        phone: _mobile.text,
        enquiryType: _type,
        source: _source,
        comment: _comment.text,
        address: _address.text,
        branchCode: _branch,
        date: DateTime.now(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on TimeoutApiException {
      if (mounted) {
        setState(
          () => _error = 'No response from the server. The lead may have been created — check the list before saving again.',
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
    final admin = context.session.can.seeAllRecords;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New lead'),
      ),
      // The branch picker needs the form metadata; staff can start typing
      // immediately because the server defaults the branch to the caller.
      body: admin
          ? AsyncView<LeadForm>(
              load: () => _repo.form(),
              what: 'the form',
              skeleton: const SkeletonDetail(),
              builder: (context, form) => _form(context, form),
            )
          : _form(context, null),
    );
  }

  Widget _form(BuildContext context, LeadForm? form) {
    final k = context.kora;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextFormField(
            controller: _mobile,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            onChanged: _onMobileChanged,
            decoration: InputDecoration(
              labelText: 'Mobile number',
              prefixText: '+91 ',
              suffixIcon: _checking
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_duplicate == false
                        ? Icon(Icons.check_circle, color: k.ok)
                        : null),
            ),
            validator: (v) => (v?.length ?? 0) < 10
                ? 'Enter a 10–15 digit mobile number'
                : null,
          ),
          if (_duplicate == true)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: k.warnContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: k.warnInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'An enquiry with this mobile number already exists. Check the lead list before adding a duplicate.',
                      style: TextStyle(color: k.warnInk),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _name,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Customer / business name',
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter the customer name' : null,
          ),
          const SizedBox(height: 18),
          const Text(
            'Enquiry for',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _chips(_types, _type, (v) => setState(() => _type = v)),
          const SizedBox(height: 18),
          const Text('Source', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _chips(_sources, _source, (v) => setState(() => _source = v)),
          if (form != null && form.branches.isNotEmpty) ...[
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _branch ?? form.defaults['bcode']?.toString(),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Assign to branch / user',
              ),
              items: [
                for (final b in form.branches)
                  DropdownMenuItem(
                    value: b.code,
                    child: Text(b.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _branch = v),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Address · optional'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _comment,
            enabled: !_busy,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Comment · optional'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: k.danger)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Save lead'),
          ),
        ],
      ),
    );
  }

  Widget _chips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    final k = context.kora;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: selected == o,
            showCheckmark: false,
            labelStyle: TextStyle(color: selected == o ? k.base : k.ink),
            onSelected: _busy ? null : (_) => onSelect(o),
          ),
      ],
    );
  }
}
