import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launch.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import 'customer_repository.dart';

/// Customer contact, licence and wallet details from three verified
/// lookups (`complaint/customer_lookup`, `bss/check_wallet`,
/// `customerpayments/getCustomerById`).
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId, this.name});

  final String customerId;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository(context.api);
    return Scaffold(
      appBar: AppBar(title: Text('Customer $customerId')),
      body: AsyncView<CustomerDetail>(
        load: () => repo.detail(customerId),
        what: 'this customer',
        skeleton: const SkeletonDetail(),
        builder: (context, c) => _body(context, c),
      ),
    );
  }

  Widget _body(BuildContext context, CustomerDetail c) {
    final k = context.kora;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (c.firmName.isNotEmpty)
                Text(c.firmName, style: TextStyle(color: k.ink3)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.phone.isEmpty ? null : () => dialPhone(c.phone),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.phone.isEmpty
                      ? null
                      : () => openWhatsApp(c.phone),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ),
        const SectionLabel('Contact'),
        CardGroup(
          children: [
            KeyValueRow('Customer ID', c.id, mono: true),
            KeyValueRow('Mobile', c.phone, mono: true),
            KeyValueRow('Email', c.email),
            KeyValueRow('Address', c.address),
          ],
        ),
        const SectionLabel('Licence'),
        CardGroup(
          children: [
            KeyValueRow('Software', c.softwareType),
            KeyValueRow('Partner', c.partnerName),
            KeyValueRow(
              'Wallet ID',
              c.walletId.isEmpty ? 'Not activated' : c.walletId,
            ),
            if (c.referralBalance != null)
              KeyValueRow('Referral balance', formatRupees(c.referralBalance)),
          ],
        ),
      ],
    );
  }
}
