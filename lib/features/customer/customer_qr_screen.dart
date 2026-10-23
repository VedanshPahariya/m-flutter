import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import 'customer_repository.dart';

/// The customer's QR code (`m/customer/qrcode`), rendered on-device from
/// `qr_url`, with referral stats.
class CustomerQrScreen extends StatelessWidget {
  const CustomerQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('My QR code')),
      body: AsyncView<CustomerQr>(
        load: repo.qr,
        what: 'your QR code',
        skeleton: const SkeletonDetail(),
        builder: (context, qr) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: k.line),
                ),
                child: qr.url.isEmpty
                    ? const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: Text('QR unavailable')),
                      )
                    : QrImageView(
                        data: qr.url,
                        size: 220,
                        backgroundColor: Colors.white,
                        semanticsLabel: 'QR code for customer ${qr.customerId}',
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(qr.customerName, style: context.text.titleMedium),
            ),
            Center(
              child: Text(
                'Customer ID ${qr.customerId}',
                style: TextStyle(color: k.ink3),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: qr.url.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: qr.url));
                        if (context.mounted) {
                          showMessage(context, 'Link copied');
                        }
                      },
                icon: const Icon(Icons.link),
                label: const Text('Copy link'),
              ),
            ),
            const SectionLabel('Referrals'),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${intOf(qr.stats, const ['total_referrals'])}',
                    label: 'Referrals',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    value: '${intOf(qr.stats, const ['converted'])}',
                    label: 'Converted',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    value: formatRupees(doubleOf(qr.stats, const ['earning'])),
                    label: 'Earned',
                  ),
                ),
              ],
            ),
            if (qr.referralAmount > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Earn ${formatRupees(qr.referralAmount)} for every referral that becomes a customer.',
                style: TextStyle(color: k.ink3),
              ),
            ],
            if (qr.company.isNotEmpty) ...[
              const SectionLabel('Support'),
              CardGroup(
                margin: EdgeInsets.zero,
                children: [
                  KeyValueRow('Company', str(qr.company, const ['name'])),
                  KeyValueRow(
                    'Phone',
                    str(qr.company, const ['mobile', 'mobile2']),
                  ),
                  KeyValueRow('Email', str(qr.company, const ['email'])),
                  KeyValueRow('Address', str(qr.company, const ['address'])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
