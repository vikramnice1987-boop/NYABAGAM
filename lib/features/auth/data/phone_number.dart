/// Phone number handling for OTP.
///
/// The OTP backend requires E.164 (`+919840012345`). Users type numbers in
/// whatever shape they are used to — with spaces, a leading zero, a `+91`
/// prefix, or none of these — so input is normalised in one place rather than
/// at each call site.
class PhoneNumber {
  const PhoneNumber._();

  /// Default country for bare 10-digit input. This app's users are in India.
  static const String defaultCountryCode = '91';

  /// Returns the number in E.164, or null when it cannot be made valid.
  static String? normalise(String raw) {
    var value = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.isEmpty) return null;

    // Keep only a leading '+', dropping any that appear mid-string.
    final hadPlus = value.startsWith('+');
    value = value.replaceAll('+', '');
    if (value.isEmpty) return null;

    if (hadPlus) {
      // Already international: trust the country code, just bounds-check.
      return value.length >= 10 && value.length <= 15 ? '+$value' : null;
    }

    // Trunk prefix used when dialling domestically.
    if (value.startsWith('0')) value = value.replaceFirst(RegExp(r'^0+'), '');
    if (value.isEmpty) return null;

    if (value.length == 10) return '+$defaultCountryCode$value';
    if (value.startsWith(defaultCountryCode) && value.length == 12) {
      return '+$value';
    }
    return null;
  }

  static bool isValid(String raw) => normalise(raw) != null;

  /// Masks all but the last two digits, for display where the full number is
  /// not needed.
  static String mask(String e164) {
    if (e164.length < 5) return e164;
    final tail = e164.substring(e164.length - 2);
    return '${e164.substring(0, 3)}${'*' * (e164.length - 5)}$tail';
  }
}
