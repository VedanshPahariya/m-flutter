import 'package:flutter_test/flutter_test.dart';
import 'package:kora_crm/features/crm/dashboard/dashboard_repository.dart';
import 'package:kora_crm/features/crm/leads/lead_repository.dart';
import 'package:kora_crm/features/crm/more/admin_repository.dart';
import 'package:kora_crm/features/crm/tickets/ticket_repository.dart';
import 'package:kora_crm/features/customer/customer_repository.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart' as fx;

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  test('tickets parse the verified complaint shape and paginate', () async {
    backend.json('POST', 'm/complaint/list', fx.complaintList);
    final page = await TicketRepository(backend.api())
        .list(status: 'New Ticket', offset: 20, showAll: true);
    expect(page.total, 9);
    final t = page.items.first;
    expect(t.id, '12');
    expect(t.code, 'CMP-12');
    expect(t.customerName, 'Sample Traders');
    expect(t.assignee, 'Staff One');
    expect(page.items[1].isUnassigned, isTrue);
    expect(page.items[1].priority, 'High');
    final body = backend.requests.single.bodyFields;
    expect(body, containsPair('status', 'New Ticket'));
    expect(body, containsPair('offset', '20'));
    expect(body, containsPair('show_all', '1'));
  });

  test('ticket counts come from cmsdashboard', () async {
    backend.json('GET', 'm/cmsdashboard', fx.cmsDashboard);
    final counts = await TicketRepository(backend.api()).counts();
    expect(counts['New Ticket'], 4);
    expect(counts['Pending OTP Verification'], 2);
  });

  test('leads: empty list and query parameters', () async {
    backend.json('GET', 'm/enquiry/list', fx.enquiryListEmpty);
    final page = await LeadRepository(backend.api())
        .list(offset: 0, status: 'Converted');
    expect(page.items, isEmpty);
    expect(page.total, 0);
    final q = backend.requests.single.url.queryParameters;
    expect(q['st'], 'Converted');
    expect(q['limit'], '20');
    expect(q.containsKey('show_all'), isFalse);
  });

  test('lead row parsing accepts the enquiry form column names', () {
    final lead = Lead.fromJson({
      'ecode': '501',
      'sname': 'Patil Traders',
      'phone': '9000000200',
      'sts': 'Call Back',
      'srs': 'Website',
      'etyp': 'New licence',
      'asgn': 'Staff One',
      'resdate': '21/10/2026',
    });
    expect(lead.id, '501');
    expect(lead.name, 'Patil Traders');
    expect(lead.status, 'Call Back');
    expect(lead.nextFollowUp, '21/10/2026');
  });

  test('new lead posts the verified field names and dd/mm/yyyy date', () async {
    backend.json(
      'POST',
      'm/enquiry/add',
      '{"status":"success","message":"Enquiry added.","data":{"id":9}}',
    );
    final msg = await LeadRepository(backend.api()).add(
      name: ' Patil Traders ',
      phone: '9000000200',
      enquiryType: 'New licence',
      source: 'Walk-in',
      date: DateTime(2026, 10, 5),
    );
    expect(msg, 'Enquiry added.');
    final body = backend.requests.single.bodyFields;
    expect(body['sname'], 'Patil Traders');
    expect(body['phone'], '9000000200');
    expect(body['sdate'], '05/10/2026');
    expect(body['etyp'], 'New licence');
    expect(body['srs'], 'Walk-in');
  });

  test('duplicate mobile check reads the bare {"exists"} response', () async {
    backend.json('POST', 'm/enquiry/check_mobile', fx.checkMobileFalse);
    expect(
      await LeadRepository(backend.api()).mobileExists('9000000003'),
      isFalse,
    );
    backend.json('POST', 'm/enquiry/check_mobile', '{"exists":true}');
    expect(
      await LeadRepository(backend.api()).mobileExists('9000000003'),
      isTrue,
    );
  });

  test('lead dashboard, renewal summary and reports', () async {
    backend
      ..json('GET', 'm/emsdashboard', fx.emsDashboard)
      ..json('GET', 'm/renewal', fx.renewal)
      ..json('GET', 'm/reports', fx.reports);
    final repo = DashboardRepository(backend.api());
    final leads = await repo.leadDashboard();
    expect(leads.count('new'), 12);
    expect(leads.count('today_callback'), 2);
    final renewal = await repo.renewalSummary(month: '2026-10');
    expect(backend.requests[1].url.queryParameters['month'], '2026-10');
    expect(renewal.target, 40);
    expect(renewal.achieved, 10);
    expect(renewal.months.first, ('2026-10', 'October 2026'));
    expect(renewal.chart.last.achieved, 250);
    final reports = await repo.reports();
    expect(reports.customers['total'], '5404');
    expect(reports.customerStatus.last, ('Unknown', 5));
  });

  test('legacy task envelope parses into a task', () {
    final task = CrmTask.fromJson({
      'id': '1',
      'title': 'wallet',
      'status': 'pending',
      'due_date': '2026-06-30',
    });
    expect(task.isDone, isFalse);
    expect(CrmTask.fromJson({'status': 'completed'}).isDone, isTrue);
  });

  test('tenants for super admin', () async {
    backend.json('GET', 'm/admin/tenants', fx.tenants);
    final list = await AdminRepository(backend.api()).tenants();
    expect(list.single.code, 'tenant_001');
    expect(list.single.users, 41);
  });

  test('customer portal home', () async {
    backend.json('GET', 'm/customer', fx.customerHome);
    final home = await CustomerPortalRepository(backend.api()).home();
    expect(home.customerId, 'DEMO001');
    expect(home.name, 'Demo Customer');
    expect(home.amc.hasAmc, isFalse);
    expect(home.amc.status, 'No AMC Record');
    expect(home.complaintCounts['Closed'], 0);
  });
}
