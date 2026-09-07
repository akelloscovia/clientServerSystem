/// Input validation helpers.
class Validators {
  /// Minimum password length. Keep in sync with the server's
  /// PASSWORD_MIN_LENGTH (config.py, default 10).
  static const int passwordMinLength = 10;

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    // Mirrors the server-side check: one @, a dotted domain, no spaces.
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$");
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  /// Client-side hint only — the server (auth_schema.py / validators.py) is the
  /// source of truth for the password policy.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Add at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Add at least one lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Add at least one digit.';
    }
    if (!value.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Add at least one symbol.';
    }
    if (value.contains(RegExp(r'\s'))) {
      return 'Password must not contain spaces.';
    }
    return null;
  }

  static String? validateRequired(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? validateMinLength(String? value, int min, [String field = 'This field']) {
    if (value == null || value.trim().length < min) {
      return '$field must be at least $min characters.';
    }
    return null;
  }
}
