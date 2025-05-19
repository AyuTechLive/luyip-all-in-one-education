import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CertificateGenerator {
  // Generate certificate PDF
  static Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required String courseName,
    required String certificateNumber,
    required String issuerName,
    required DateTime issueDate,
    required double percentageScore,
  }) async {
    final pdf = pw.Document();

    // Load certificate template assets
    final logoImage = await _loadPdfImageFromAsset('assets/logo.png');
    final backgroundImage =
        await _loadPdfImageFromAsset('assets/certificate_background.png');
    final signatureImage = await _loadPdfImageFromAsset('assets/signature.png');
    final stampImage = await _loadPdfImageFromAsset('assets/stamp.png');

    // Font for certificate title
    // Fix: Use the correct font loading methods
    final headlineFont = await PdfGoogleFonts.playfairDisplayBold();
    final bodyFont =
        await PdfGoogleFonts.openSansRegular(); // Fixed method name
    final titleFont = await PdfGoogleFonts.montserratBold();

    // Certificate page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background image
              pw.Positioned.fill(
                child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
              ),

              // Certificate content
              pw.Container(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo
                    pw.Container(
                      height: 60,
                      child: pw.Image(logoImage),
                    ),

                    pw.SizedBox(height: 20),

                    // Certificate title
                    pw.Text(
                      'CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        font: titleFont,
                        fontSize: 24,
                        color: PdfColors.blueGrey800,
                      ),
                    ),

                    pw.SizedBox(height: 10),

                    // Decorative line
                    pw.Container(
                      width: 200,
                      height: 1,
                      color: PdfColors.blueGrey500,
                    ),

                    pw.SizedBox(height: 30),

                    // Student name
                    pw.Text(
                      'This is to certify that',
                      style: pw.TextStyle(font: bodyFont, fontSize: 12),
                    ),

                    pw.SizedBox(height: 15),

                    pw.Text(
                      studentName,
                      style: pw.TextStyle(
                        font: headlineFont,
                        fontSize: 32,
                        color: PdfColors.blueGrey900,
                      ),
                    ),

                    pw.SizedBox(height: 15),

                    // Course info
                    pw.Text(
                      'has successfully completed the course',
                      style: pw.TextStyle(font: bodyFont, fontSize: 12),
                    ),

                    pw.SizedBox(height: 15),

                    pw.Text(
                      courseName,
                      style: pw.TextStyle(
                        font: titleFont,
                        fontSize: 20,
                        color: PdfColors.blue800,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),

                    pw.SizedBox(height: 15),

                    // Score
                    pw.Text(
                      'with a score of ${percentageScore.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        font: bodyFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 40),

                    // Date and signatures row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Issue date
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              DateFormat('MMMM dd, yyyy').format(issueDate),
                              style: pw.TextStyle(
                                font: bodyFont,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              width: 150,
                              height: 1,
                              color: PdfColors.grey,
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Date of Issue',
                              style: pw.TextStyle(
                                font: bodyFont,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // Signature
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              height: 50,
                              child: pw.Image(signatureImage),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              width: 150,
                              height: 1,
                              color: PdfColors.grey,
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              issuerName,
                              style: pw.TextStyle(
                                font: bodyFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Course Instructor',
                              style: pw.TextStyle(
                                font: bodyFont,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // Stamp
                        pw.Container(
                          height: 80,
                          child: pw.Image(stampImage),
                        ),
                      ],
                    ),

                    pw.Spacer(),

                    // Certificate number and verification
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Certificate ID: $certificateNumber',
                          style: pw.TextStyle(
                            font: bodyFont,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Verify at: luyip.edu/verify',
                          style: pw.TextStyle(
                            font: bodyFont,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper to load image from asset
  static Future<pw.ImageProvider> _loadPdfImageFromAsset(
      String assetPath) async {
    // In a real implementation, you would load actual assets
    // This is a placeholder that creates a simple colored box

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..color = Colors.blue;

    // Draw a simple shape based on the asset type
    if (assetPath.contains('logo')) {
      canvas.drawCircle(const ui.Offset(50, 50), 50, paint);
    } else if (assetPath.contains('background')) {
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), paint);
    } else if (assetPath.contains('signature')) {
      final signaturePaint = ui.Paint()..color = Colors.black;
      canvas.drawLine(
          const ui.Offset(0, 50), const ui.Offset(100, 50), signaturePaint);
    } else if (assetPath.contains('stamp')) {
      canvas.drawCircle(const ui.Offset(40, 40), 40,
          paint..color = Colors.red.withOpacity(0.3));
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (imgBytes == null) {
      throw Exception('Failed to create image for $assetPath');
    }

    // Convert to pw.ImageProvider (for use with pdf widgets library)
    return pw.MemoryImage(imgBytes.buffer.asUint8List());
  }

  // Upload certificate to Firebase Storage and return URL
  static Future<String> uploadCertificate({
    required String certificateNumber,
    required Uint8List pdfBytes,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('certificates/$certificateNumber.pdf');

      // Upload the PDF file
      await storageRef.putData(pdfBytes);

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload certificate: $e');
    }
  }

  // Generate and upload certificate
  static Future<String> generateAndUploadCertificate({
    required String studentName,
    required String courseName,
    required String certificateNumber,
    required String issuerName,
    required DateTime issueDate,
    required double percentageScore,
  }) async {
    try {
      // Generate the PDF
      final pdfBytes = await generateCertificatePdf(
        studentName: studentName,
        courseName: courseName,
        certificateNumber: certificateNumber,
        issuerName: issuerName,
        issueDate: issueDate,
        percentageScore: percentageScore,
      );

      // Upload to Firebase Storage
      final downloadUrl = await uploadCertificate(
        certificateNumber: certificateNumber,
        pdfBytes: pdfBytes,
      );

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to generate and upload certificate: $e');
    }
  }
}
