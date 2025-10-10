/// Utility class for input validation across the Health Buddy app
/// Provides consistent validation for email addresses, phone numbers, and other inputs
class Validators {
  /// Validates email address format
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    // Strict email validation pattern
    // Allows: letters, numbers, dots, underscores, percent, plus, hyphens
    // Before @ symbol and standard domain format after
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value.trim())) {
      return 'Please enter a valid email address (e.g., user@example.com)';
    }

    return null;
  }

  /// Validates phone number format (10 digits, cannot start with 0 or 1)
  /// Returns error message if invalid, null if valid
  static String? validatePhoneNumber(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a phone number' : null;
    }

    // Remove all non-digits for validation
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedValue.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    // Check if it starts with valid digits (not 0 or 1)
    if (cleanedValue.startsWith('0') || cleanedValue.startsWith('1')) {
      return 'Phone number cannot start with 0 or 1';
    }

    return null;
  }

  /// Validates password strength
  /// Returns error message if invalid, null if valid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates password confirmation
  /// Returns error message if passwords don't match, null if valid
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates full name
  /// Returns error message if invalid, null if valid
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    // Check if name contains only letters, spaces, apostrophes, and hyphens
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, apostrophes, and hyphens';
    }

    return null;
  }

  /// Validates required text fields
  /// Returns error message if empty, null if valid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates age (must be between 1 and 150)
  /// Returns error message if invalid, null if valid
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter age';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < 1 || age > 150) {
      return 'Please enter a valid age between 1 and 150';
    }

    return null;
  }

  /// Validates doctor ID format
  /// Returns error message if invalid, null if valid
  static String? validateDoctorId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Doctor ID';
    }

    // Doctor ID should be alphanumeric and at least 3 characters
    if (value.trim().length < 3) {
      return 'Doctor ID must be at least 3 characters long';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
      return 'Doctor ID can only contain letters and numbers';
    }

    return null;
  }

  /// Validates license number format
  /// Returns error message if invalid, null if valid
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter license number';
    }

    // License number should be alphanumeric and at least 5 characters
    if (value.trim().length < 5) {
      return 'License number must be at least 5 characters long';
    }

    if (!RegExp(r'^[a-zA-Z0-9\-/]+$').hasMatch(value.trim())) {
      return 'License number can only contain letters, numbers, hyphens, and forward slashes';
    }

    return null;
  }

  /// Validates consultation fee
  /// Returns error message if invalid, null if valid
  static String? validateConsultationFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter consultation fee';
    }

    final fee = double.tryParse(value);
    if (fee == null) {
      return 'Please enter a valid amount';
    }

    if (fee < 0) {
      return 'Consultation fee cannot be negative';
    }

    if (fee > 50000) {
      return 'Please enter a reasonable consultation fee';
    }

    return null;
  }
}
