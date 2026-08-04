import 'package:equatable/equatable.dart';

/// A job_parts record linking a spare part to an active technician job.
class JobPart extends Equatable {
  final String id;
  final String jobId;
  final String partId;
  final int quantity;
  final double technicianPrice;
  final double customerPrice;
  final double profitMargin;
  final String? partName;
  final String? category;
  final DateTime createdAt;

  const JobPart({
    required this.id,
    required this.jobId,
    required this.partId,
    required this.quantity,
    required this.technicianPrice,
    required this.customerPrice,
    required this.profitMargin,
    this.partName,
    this.category,
    required this.createdAt,
  });

  factory JobPart.fromJson(Map<String, dynamic> json) {
    return JobPart(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      partId: json['part_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      technicianPrice: (json['technician_price'] as num?)?.toDouble() ?? 0.0,
      customerPrice: (json['customer_price'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      partName: json['part_name']?.toString(),
      category: json['category']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'job_id': jobId,
        'part_id': partId,
        'quantity': quantity,
        'technician_price': technicianPrice,
        'customer_price': customerPrice,
        'profit_margin': profitMargin,
      };

  @override
  List<Object?> get props => [
        id, jobId, partId, quantity, technicianPrice, customerPrice,
        profitMargin, partName, category, createdAt,
      ];
}

/// Required Supabase schema (run once):
/// ```sql
/// CREATE TABLE IF NOT EXISTS job_parts (
///   id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///   job_id           uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
///   part_id          uuid NOT NULL REFERENCES spare_parts(id),
///   quantity         int  NOT NULL DEFAULT 1,
///   technician_price numeric(10,2) NOT NULL,
///   customer_price   numeric(10,2) NOT NULL,
///   profit_margin    numeric(10,2) GENERATED ALWAYS AS (customer_price - technician_price) STORED,
///   created_at       timestamptz NOT NULL DEFAULT now()
/// );
/// -- RLS: technicians may insert/select only rows whose job belongs to them.
/// ALTER TABLE job_parts ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "Technician owns job" ON job_parts
///   USING (job_id IN (SELECT id FROM jobs WHERE technician_id = auth.uid()::text));
/// ```
