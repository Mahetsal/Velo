/// Normalizes a Jordan phone number to the international format +962XXXXXXXXX.
///
/// Handles common input formats:
/// - `07XXXXXXXX` (local with leading zero)
/// - `7XXXXXXXX`  (9 digits, no prefix)
/// - `962XXXXXXXXX` (country code without +)
/// - `+962XXXXXXXXX` (already international)
String normalizeJordanPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('962') && digits.length >= 12) {
    return '+$digits';
  }
  if (digits.startsWith('0') && digits.length == 10) {
    return '+962${digits.substring(1)}';
  }
  if (digits.length == 9) {
    return '+962$digits';
  }
  if (phone.trim().startsWith('+')) {
    return phone.trim();
  }
  return '+$digits';
}
