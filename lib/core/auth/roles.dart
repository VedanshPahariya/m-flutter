/// Roles discovered in the API inventory.
///
/// * `customer` and `seeker` come straight from `user_type` in the login and
///   `m/auth/me` responses.
/// * Every CRM user has `user_type: staff`. The CRM role is not in the token
///   or in `m/auth/me`; it is read from `POST m/dashboard/index`, which
///   returns `staff.role` (1 = branch admin, 2 = staff) and
///   `staff.is_super_admin`.
///
/// The role is resolved from the server on every sign-in and session restore
/// and is never persisted, so a stale or edited local value cannot grant
/// access. The backend still enforces every permission.
enum AppRole { customer, seeker, staff, branchAdmin, superAdmin }

extension AppRoleX on AppRole {
  bool get isCrm =>
      this == AppRole.staff ||
      this == AppRole.branchAdmin ||
      this == AppRole.superAdmin;

  String get label => switch (this) {
    AppRole.customer => 'Customer',
    AppRole.seeker => 'Job seeker',
    AppRole.staff => 'Staff',
    AppRole.branchAdmin => 'Branch admin',
    AppRole.superAdmin => 'Super admin',
  };
}

/// Resolves the CRM role from the `m/dashboard/index` staff block.
///
/// Unknown or missing values fall back to [AppRole.staff], the least
/// privileged CRM role.
AppRole resolveStaffRole({Object? role, Object? isSuperAdmin}) {
  final superFlag =
      isSuperAdmin == true ||
      isSuperAdmin == 1 ||
      isSuperAdmin == '1' ||
      isSuperAdmin == 'true';
  if (superFlag) return AppRole.superAdmin;
  final value = role is int ? role : int.tryParse('${role ?? ''}');
  if (value == 1) return AppRole.branchAdmin;
  return AppRole.staff;
}

/// Client-side permission map. It only decides what the UI offers; the
/// server is authoritative and a 403 is always handled.
///
/// Derived from the prototype's "access by role" notes and from the
/// inventory: admin-only endpoints answer 403 "Admin access required" for
/// staff, and the super-admin inventory covers `m/admin`, `m/autoassign`
/// and `m/qradmin`.
class Permissions {
  const Permissions(this.role);

  final AppRole role;

  bool get _admin => role == AppRole.branchAdmin || role == AppRole.superAdmin;

  bool get deleteLead => _admin;
  bool get seeAllRecords => _admin;
  bool get approveSignups => _admin;
  bool get toggleTeamMembers => _admin;
  bool get viewPayments => role.isCrm;
  bool get autoAssignTickets => role == AppRole.superAdmin;
  bool get platformAdmin => role == AppRole.superAdmin;
}
