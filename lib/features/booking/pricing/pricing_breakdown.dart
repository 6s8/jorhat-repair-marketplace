/// Pricing breakdown helper — all calculations in-app, no extra DB columns needed.
///
/// Live DB stores a single `price` field (= customer total).
/// Platform fee is 20%, technician payout is 80%.
class PricingBreakdown {
  static const double platformFeeRate = 0.20; // 20% platform commission
  static const double technicianPayoutRate = 0.80; // 80% to technician

  final double baseServiceCharge; // Base labor rate (original job price)
  final double spareParts; // Added by technician during active job

  const PricingBreakdown({
    required this.baseServiceCharge,
    this.spareParts = 0.0,
  });

  /// Total the customer pays = service + parts
  double get customerTotal => baseServiceCharge + spareParts;

  /// Platform commission (20% of customer total)
  double get platformFee => customerTotal * platformFeeRate;

  /// Net payout to technician (80% of customer total)
  double get technicianPayout => customerTotal * technicianPayoutRate;

  /// Formatted strings
  String get customerTotalStr => '₹${customerTotal.toStringAsFixed(0)}';
  String get technicianPayoutStr => '₹${technicianPayout.toStringAsFixed(0)}';
  String get platformFeeStr => '₹${platformFee.toStringAsFixed(0)}';
  String get baseServiceStr => '₹${baseServiceCharge.toStringAsFixed(0)}';
  String get sparePartsStr => '₹${spareParts.toStringAsFixed(0)}';

  PricingBreakdown withSpareParts(double parts) => PricingBreakdown(
        baseServiceCharge: baseServiceCharge,
        spareParts: parts,
      );
}
