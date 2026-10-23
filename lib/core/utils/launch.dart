import 'package:url_launcher/url_launcher.dart';

/// Digits only, with India's country code added to 10-digit numbers.
String normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '91$digits';
  return digits;
}

Future<bool> dialPhone(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return false;
  try {
    return await launchUrl(Uri(scheme: 'tel', path: digits));
  } catch (_) {
    return false;
  }
}

Future<bool> openWhatsApp(String phone, {String? text}) async {
  final number = normalizePhone(phone);
  if (number.isEmpty) return false;
  final uri = Uri.https('wa.me', '/$number', {'text': ?text});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
