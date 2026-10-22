import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// A row of the customer directory.
///
/// `m/customerdir/list` returned no rows in the inventory. The keys are the
/// party-master columns seen in `m/bulkmsg/get_bulk_msg_clients` and the
/// customer portal (`Customer_ID`, `Party_Name`, `Mobile`, `Party_Status`,
/// `Due_On`, `City`).
class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.dueOn,
    required this.city,
    required this.softwareType,
  });

  factory CustomerSummary.fromJson(JsonMap j) => CustomerSummary(
    id: str(j, const ['Customer_ID', 'customer_id', 'id']),
    name: str(j, const [
      'Party_Name',
      'party_name',
      'name',
      'customer_name',
    ], 'Unnamed'),
    mobile: str(j, const ['Mobile', 'mobile', 'phone']),
    status: str(j, const ['Party_Status', 'party_status', 'status']),
    dueOn: str(j, const ['Due_On', 'due_on', 'due_date', 'amc_due']),
    city: str(j, const ['City', 'city', 'Pincode', 'pincode']),
    softwareType: str(j, const [
      'sw_type',
      'Software_Type',
      'software_type',
      'Edition',
    ]),
  );

  final String id;
  final String name;
  final String mobile;
  final String status;
  final String dueOn;
  final String city;
  final String softwareType;
}

/// Combined customer record for the detail screen.
class CustomerDetail {
  const CustomerDetail({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.firmName,
    required this.partnerName,
    required this.softwareType,
    required this.walletId,
    required this.referralBalance,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String firmName;
  final String partnerName;
  final String softwareType;
  final String walletId;
  final double? referralBalance;
}

class CustomerRepository {
  const CustomerRepository(this._api);

  final ApiClient _api;

  Future<PageResult<CustomerSummary>> list({
    required int offset,
    String search = '',
  }) async {
    const perPage = 50;
    final json = await _api.post(
      Endpoints.customerDirectory,
      body: {
        'page': offset ~/ perPage + 1,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final items = dataList(
      json,
      'customers',
    ).map(CustomerSummary.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(
        dataMap(json),
        fallbackLimit: perPage,
        loaded: offset + items.length,
      ).total,
    );
  }

  /// Loads the three verified lookups in parallel; each one is optional so
  /// a missing wallet record does not hide the rest.
  Future<CustomerDetail> detail(String customerId) async {
    final results = await Future.wait<Object?>([
      _api.post(
        Endpoints.complaintCustomerLookup,
        body: {'customer_id': customerId},
      ),
      _optional(() => _api.get(Endpoints.walletCheck(customerId))),
      _optional(
        () => _api.post(
          Endpoints.customerById,
          body: {'customer_id': customerId},
        ),
      ),
    ]);
    final lookup = asMap(results[0]);
    final wallet = dataMap(results[1]);
    final byId = asMap(asMap(results[2])['customer']);
    return CustomerDetail(
      id: customerId,
      name: str(lookup, const ['name']).isNotEmpty
          ? str(lookup, const ['name'])
          : str(wallet, const [
              'party_name',
            ], str(byId, const ['name'], 'Customer')),
      phone: str(lookup, const [
        'phone',
      ], str(wallet, const ['mobile'], str(byId, const ['mobile']))),
      email: str(lookup, const ['email']),
      address: str(lookup, const ['address'], str(wallet, const ['address'])),
      firmName: str(lookup, const ['firm_name']),
      partnerName: str(lookup, const ['partner_name']),
      softwareType: str(wallet, const ['sw_type']),
      walletId: str(wallet, const ['wallet_id']),
      referralBalance: parseDouble(byId['referral_balance']),
    );
  }

  Future<Object?> _optional(Future<Object?> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }
}
