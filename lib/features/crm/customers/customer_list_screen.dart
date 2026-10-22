import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import 'customer_detail_screen.dart';
import 'customer_repository.dart';

/// AMC due date → tone and label, as on the prototype's customer rows.
(Color, String) amcTone(BuildContext context, String dueOn) {
  final k = context.kora;
  final due = parseDate(dueOn);
  if (due == null) return (k.mute, dueOn.isEmpty ? 'No AMC date' : dueOn);
  final days = DateUtils.dateOnly(due)
      .difference(DateUtils.dateOnly(DateTime.now()))
      .inDays;
  if (days < 0) return (k.danger, 'Expired ${-days}d');
  if (days == 0) return (k.danger, 'Expires today');
  if (days <= 30) return (k.warn, formatDate(due, withYear: false));
  return (k.ok, formatDate(due));
}

/// `POST m/customerdir/list` with server-side search.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository(context.api);
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(
              controller: _search,
              hint: 'Name, customer ID or mobile',
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const Divider(),
          Expanded(
            child: PagedListView<CustomerSummary>(
              key: ValueKey(_query),
              what: 'customers',
              fetch: (offset) => repo.list(offset: offset, search: _query),
              empty: (_) => _query.isEmpty
                  ? const EmptyView(
                      icon: Icons.storefront_outlined,
                      title: 'No customers in your directory',
                    )
                  : EmptyView(
                      icon: Icons.search_off,
                      title: 'No customers match “$_query”',
                      message: 'Try a customer ID or mobile number.',
                      action: OutlinedButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        child: const Text('Clear search'),
                      ),
                    ),
              itemBuilder: (context, c, _) => CustomerRow(customer: c),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerRow extends StatelessWidget {
  const CustomerRow({super.key, required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final (tone, label) = amcTone(context, customer.dueOn);
    final meta = [
      customer.id,
      customer.softwareType,
      customer.city,
    ].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: customer.id.isEmpty
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(
                  customerId: customer.id,
                  name: customer.name,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: k.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('AMC', style: TextStyle(fontSize: 11, color: k.mute)),
                StatusLabel(label, color: tone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
