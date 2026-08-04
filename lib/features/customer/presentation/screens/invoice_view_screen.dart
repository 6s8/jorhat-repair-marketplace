import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../models/job_model.dart';

class InvoiceViewScreen extends StatelessWidget {
  final Job job;

  const InvoiceViewScreen({super.key, required this.job});

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    const double baseServiceCharge = 399.0;
    final double totalAmount = job.price;
    final double partsTotal = totalAmount > baseServiceCharge ? totalAmount - baseServiceCharge : 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Jorhat Repair', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue800)),
                      pw.Text('& Spare Parts Marketplace', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE / RECEIPT', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: ${dateFormat.format(job.createdAt)}', style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text('Time: ${timeFormat.format(job.createdAt)}', style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text('Job ID: ${job.id.length >= 8 ? job.id.substring(0, 8) : job.id}', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Customer Info
              pw.Text('Billed To:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text(job.customerName ?? 'Customer', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              if (job.customerPhone != null) pw.Text('Phone: ${job.customerPhone}', style: pw.TextStyle(font: font, fontSize: 12)),
              if (job.addressText != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Address: ${job.addressText}', style: pw.TextStyle(font: font, fontSize: 12)),
              ],
              pw.SizedBox(height: 20),
              pw.Text('Service Provided:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text(job.applianceCategory ?? 'General Repair', style: pw.TextStyle(font: font, fontSize: 12)),
              
              pw.SizedBox(height: 30),

              // Itemized Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (₹)', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Base Charge
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Base Service Charge', style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(baseServiceCharge.toStringAsFixed(2), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Spare Parts
                  if (job.sparePartsUsed != null && job.sparePartsUsed!.isNotEmpty)
                    ...job.sparePartsUsed!.entries.map((entry) {
                      final rawVal = entry.value;
                      final price = rawVal is num ? rawVal.toDouble() : double.tryParse(rawVal.toString()) ?? 0.0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Spare Part: ${entry.key}', style: pw.TextStyle(font: font))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                        ],
                      );
                    })
                  else if (partsTotal > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Spare Parts (Bulk Entry)', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(partsTotal.toStringAsFixed(2), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Paid:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                        pw.Text('₹${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue800)),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for choosing Jorhat Repair Marketplace!', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ),
              pw.Center(
                child: pw.Text('This is a system generated invoice.', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, 'Invoice_${job.id.length >= 8 ? job.id.substring(0, 8) : job.id}'),
        allowSharing: true,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Invoice_JorhatRepair_${job.id.length >= 8 ? job.id.substring(0, 8) : job.id}.pdf',
      ),
    );
  }
}
