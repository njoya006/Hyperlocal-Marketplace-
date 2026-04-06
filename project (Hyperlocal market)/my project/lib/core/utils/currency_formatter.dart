/// Currency formatting utilities for XAF (Central African CFA franc).
class CurrencyFormatter {
  /// Formats a number as XAF currency.
  /// 
  /// Example: formatXAF(1234.5) => "XAF 1,234.50"
  static String formatXAF(double amount) {
    return 'XAF ${amount.toStringAsFixed(2)}';
  }

  /// Formats a number as XAF with compact notation.
  ///
  /// Example: formatXAFCompact(1234.5) => "XAF 1.23k"
  static String formatXAFCompact(double amount) {
    if (amount >= 1000000) {
      return 'XAF ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'XAF ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return formatXAF(amount);
  }

  /// Parse amount from XAF formatted string.
  /// 
  /// Example: parseXAF("XAF 1,234.50") => 1234.50
  static double? parseXAF(String formatted) {
    try {
      final cleaned = formatted
          .replaceAll('XAF', '')
          .replaceAll(',', '')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
