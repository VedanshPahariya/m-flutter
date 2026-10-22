import '../utils/json.dart';
import 'roles.dart';

/// Which login endpoint created the session.
enum AccountKind { staff, customer, seeker }

/// Tokens issued by `m/auth/login`, `m/auth/seeker_login`,
/// `m/auth/verifyOTP` and `m/auth/refresh`.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Parses the `data` block of a login or refresh response.
  factory AuthTokens.fromData(JsonMap data, {DateTime? now}) {
    final access = str(data, const ['access_token', 'token']);
    final refresh = str(data, const ['refresh_token']);
    if (access.isEmpty) {
      throw const FormatException('Response has no access_token');
    }
    final expiresIn = intOf(data, const ['expires_in'], 3600);
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: (now ?? DateTime.now()).add(Duration(seconds: expiresIn)),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// True when the token expires within [margin]; refreshing a little early
  /// avoids a guaranteed 401 round trip on a slow network.
  bool expiresWithin(Duration margin, {DateTime? now}) =>
      (now ?? DateTime.now()).add(margin).isAfter(expiresAt);

  Map<String, String> toStorage() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };

  static AuthTokens? fromStorage(Map<String, String> values) {
    final access = values['access_token'];
    final refresh = values['refresh_token'];
    final expires = DateTime.tryParse(values['expires_at'] ?? '');
    if (access == null || refresh == null || refresh.isEmpty) return null;
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expires?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// The signed-in user as reported by the server.
class UserProfile {
  const UserProfile({
    required this.userType,
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    this.tenantCode,
    this.branchName,
    this.forceChange = false,
  });

  /// Parses `m/auth/me` or the login `data` block.
  factory UserProfile.fromJson(JsonMap data) => UserProfile(
    userType: str(data, const ['user_type']),
    userId: str(data, const ['user_id', 'id']),
    name: str(data, const ['name', 'full_name'], 'User'),
    email: strOrNull(data, const ['email']),
    mobile: strOrNull(data, const ['mobile', 'phone']),
    tenantCode: strOrNull(data, const ['tenant_code']),
    branchName: strOrNull(data, const ['branch_name']),
    forceChange: boolOf(data, const ['force_change']),
  );

  final String userType;
  final String userId;
  final String name;
  final String? email;
  final String? mobile;
  final String? tenantCode;
  final String? branchName;
  final bool forceChange;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  UserProfile copyWith({bool? forceChange}) => UserProfile(
    userType: userType,
    userId: userId,
    name: name,
    email: email,
    mobile: mobile,
    tenantCode: tenantCode,
    branchName: branchName,
    forceChange: forceChange ?? this.forceChange,
  );
}

/// A fully established session: server-confirmed user and resolved role.
class Session {
  const Session({required this.user, required this.role});

  final UserProfile user;
  final AppRole role;

  Permissions get can => Permissions(role);
}

/// Maps `user_type` to the account kind used for routing.
AccountKind? accountKindOf(String userType) => switch (userType) {
  'staff' => AccountKind.staff,
  'customer' => AccountKind.customer,
  'seeker' => AccountKind.seeker,
  _ => null,
};
