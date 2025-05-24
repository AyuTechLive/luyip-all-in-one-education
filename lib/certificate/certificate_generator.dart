import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CertificateGenerator {
  // Generate professional certificate PDF
  static Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required String courseName,
    required String certificateNumber,
    required String issuerName,
    required DateTime issueDate,
    required double percentageScore,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final headlineFont = await PdfGoogleFonts.playfairDisplayBold();
    final bodyFont = await PdfGoogleFonts.openSansRegular();
    final titleFont = await PdfGoogleFonts.montserratBold();
    final lightFont = await PdfGoogleFonts.openSansLight();
    final semiBoldFont = await PdfGoogleFonts.openSansSemiBold();

    // Load certificate template assets
    final logoImage = await _loadPdfImageFromAsset('assets/logo.png');
    final signatureImage = await _loadPdfImageFromAsset('assets/signature.png');
    final sealImage = await _loadPdfImageFromAsset('assets/seal.png');

    // Create QR code for verification
    final qrCodeImage = await _generateQRCode(certificateNumber);

    // Certificate page with premium design
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Elegant background with gradient effect
              _buildBackgroundDesign(),

              // Main certificate content
              pw.Container(
                padding: const pw.EdgeInsets.all(60),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header with logo and institution name
                    _buildCertificateHeader(logoImage, titleFont, bodyFont),

                    pw.SizedBox(height: 40),

                    // Certificate title with decorative elements
                    _buildCertificateTitle(titleFont, headlineFont),

                    pw.SizedBox(height: 35),

                    // Student name section
                    _buildStudentNameSection(
                        studentName, headlineFont, lightFont),

                    pw.SizedBox(height: 30),

                    // Course information
                    _buildCourseSection(courseName, titleFont, bodyFont),

                    pw.SizedBox(height: 25),

                    // Achievement details
                    _buildAchievementSection(
                        percentageScore, semiBoldFont, bodyFont),

                    pw.SizedBox(height: 40),

                    // Credentials and verification section
                    _buildCredentialsSection(
                      issueDate,
                      certificateNumber,
                      issuerName,
                      signatureImage,
                      sealImage,
                      qrCodeImage,
                      bodyFont,
                      semiBoldFont,
                      lightFont,
                    ),
                  ],
                ),
              ),

              // Decorative borders and elements
              _buildDecorativeBorders(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Build elegant background design
  static pw.Widget _buildBackgroundDesign() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColor.fromHex('#f8f9fa'),
            PdfColor.fromHex('#ffffff'),
            PdfColor.fromHex('#f1f3f4'),
          ],
        ),
      ),
    );
  }

  // Build certificate header
  static pw.Widget _buildCertificateHeader(
      pw.ImageProvider logoImage, pw.Font titleFont, pw.Font bodyFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          height: 80,
          width: 80,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(40),
            border: pw.Border.all(
              color: PdfColor.fromHex('#1565c0'),
              width: 3,
            ),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 37,
            verticalRadius: 37,
            child: pw.Image(logoImage, fit: pw.BoxFit.cover),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LUIYP EDUCATIONAL INSTITUTE',
              style: pw.TextStyle(
                font: titleFont,
                fontSize: 18,
                color: PdfColor.fromHex('#1565c0'),
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Excellence in Education & Professional Development',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 11,
                color: PdfColor.fromHex('#666666'),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build certificate title with decorative elements
  static pw.Widget _buildCertificateTitle(
      pw.Font titleFont, pw.Font headlineFont) {
    return pw.Column(
      children: [
        // Decorative line
        pw.Container(
          width: 150,
          height: 2,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#1565c0'),
                PdfColor.fromHex('#42a5f5'),
                PdfColor.fromHex('#1565c0'),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 20),

        pw.Text(
          'CERTIFICATE',
          style: pw.TextStyle(
            font: headlineFont,
            fontSize: 36,
            color: PdfColor.fromHex('#1565c0'),
            letterSpacing: 8,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'OF COMPLETION',
          style: pw.TextStyle(
            font: titleFont,
            fontSize: 20,
            color: PdfColor.fromHex('#37474f'),
            letterSpacing: 4,
          ),
        ),

        pw.SizedBox(height: 20),
        // Decorative line
        pw.Container(
          width: 150,
          height: 2,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#1565c0'),
                PdfColor.fromHex('#42a5f5'),
                PdfColor.fromHex('#1565c0'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build student name section
  static pw.Widget _buildStudentNameSection(
      String studentName, pw.Font headlineFont, pw.Font lightFont) {
    return pw.Column(
      children: [
        pw.Text(
          'This is to certify that',
          style: pw.TextStyle(
            font: lightFont,
            fontSize: 14,
            color: PdfColor.fromHex('#555555'),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromHex('#e0e0e0'),
              width: 1,
            ),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            studentName.toUpperCase(),
            style: pw.TextStyle(
              font: headlineFont,
              fontSize: 32,
              color: PdfColor.fromHex('#1565c0'),
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  // Build course section
  static pw.Widget _buildCourseSection(
      String courseName, pw.Font titleFont, pw.Font bodyFont) {
    return pw.Column(
      children: [
        pw.Text(
          'has successfully completed the comprehensive course',
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 14,
            color: PdfColor.fromHex('#555555'),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f5f5f5'),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(
              color: PdfColor.fromHex('#1565c0'),
              width: 1,
            ),
          ),
          child: pw.Text(
            courseName,
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 22,
              color: PdfColor.fromHex('#1565c0'),
              letterSpacing: 1,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Build achievement section
  static pw.Widget _buildAchievementSection(
      double percentageScore, pw.Font semiBoldFont, pw.Font bodyFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#e8f5e8'),
            borderRadius: pw.BorderRadius.circular(20),
            border: pw.Border.all(
              color: PdfColor.fromHex('#4caf50'),
              width: 1,
            ),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'Achievement Score: ',
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 12,
                  color: PdfColor.fromHex('#2e7d32'),
                ),
              ),
              pw.Text(
                '${percentageScore.toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  font: semiBoldFont,
                  fontSize: 16,
                  color: PdfColor.fromHex('#1b5e20'),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#fff3e0'),
            borderRadius: pw.BorderRadius.circular(20),
            border: pw.Border.all(
              color: PdfColor.fromHex('#ff9800'),
              width: 1,
            ),
          ),
          child: pw.Text(
            percentageScore >= 90
                ? 'DISTINCTION'
                : percentageScore >= 80
                    ? 'MERIT'
                    : 'PASS',
            style: pw.TextStyle(
              font: semiBoldFont,
              fontSize: 12,
              color: PdfColor.fromHex('#e65100'),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // Build credentials and verification section
  static pw.Widget _buildCredentialsSection(
    DateTime issueDate,
    String certificateNumber,
    String issuerName,
    pw.ImageProvider signatureImage,
    pw.ImageProvider sealImage,
    pw.ImageProvider qrCodeImage,
    pw.Font bodyFont,
    pw.Font semiBoldFont,
    pw.Font lightFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Date and certificate info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#e0e0e0'),
                  width: 1,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Issue Date:',
                    style: pw.TextStyle(
                      font: lightFont,
                      fontSize: 10,
                      color: PdfColor.fromHex('#666666'),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    DateFormat('MMMM dd, yyyy').format(issueDate),
                    style: pw.TextStyle(
                      font: semiBoldFont,
                      fontSize: 12,
                      color: PdfColor.fromHex('#333333'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Certificate ID:',
                    style: pw.TextStyle(
                      font: lightFont,
                      fontSize: 10,
                      color: PdfColor.fromHex('#666666'),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    certificateNumber,
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 10,
                      color: PdfColor.fromHex('#1565c0'),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Verify at: luyip.edu/verify',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: PdfColor.fromHex('#1565c0'),
              ),
            ),
          ],
        ),

        // Signature section
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              height: 60,
              width: 150,
              child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 5),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColor.fromHex('#cccccc'),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              issuerName,
              style: pw.TextStyle(
                font: semiBoldFont,
                fontSize: 12,
                color: PdfColor.fromHex('#333333'),
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: lightFont,
                fontSize: 10,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
            pw.Text(
              'LUYIP Educational Institute',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ],
        ),

        // Seal and QR code
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              height: 80,
              width: 80,
              child: pw.Image(sealImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 50,
              width: 50,
              child: pw.Image(qrCodeImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Scan to Verify',
              style: pw.TextStyle(
                font: lightFont,
                fontSize: 8,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build decorative borders
  static pw.Widget _buildDecorativeBorders() {
    return pw.Stack(
      children: [
        // Top border
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 6,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#1565c0'),
                  PdfColor.fromHex('#42a5f5'),
                  PdfColor.fromHex('#1565c0'),
                ],
              ),
            ),
          ),
        ),
        // Bottom border
        pw.Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 6,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#1565c0'),
                  PdfColor.fromHex('#42a5f5'),
                  PdfColor.fromHex('#1565c0'),
                ],
              ),
            ),
          ),
        ),
        // Left border
        pw.Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: pw.Container(
            width: 6,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
                colors: [
                  PdfColor.fromHex('#1565c0'),
                  PdfColor.fromHex('#42a5f5'),
                  PdfColor.fromHex('#1565c0'),
                ],
              ),
            ),
          ),
        ),
        // Right border
        pw.Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: pw.Container(
            width: 6,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
                colors: [
                  PdfColor.fromHex('#1565c0'),
                  PdfColor.fromHex('#42a5f5'),
                  PdfColor.fromHex('#1565c0'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper to load image from asset
  static Future<pw.ImageProvider> _loadPdfImageFromAsset(
      String assetPath) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    if (assetPath.contains('logo')) {
      // Create a professional logo placeholder
      final paint = ui.Paint()
        ..color = const Color(0xFF1565C0)
        ..style = ui.PaintingStyle.fill;

      canvas.drawCircle(const ui.Offset(50, 50), 45, paint);

      final textPaint = ui.Paint()..color = Colors.white;
      canvas.drawCircle(const ui.Offset(50, 50), 35, textPaint);

      // Add "L" for LUYIP using simple shapes
      final letterPaint = ui.Paint()
        ..color = const Color(0xFF1565C0)
        ..style = ui.PaintingStyle.fill;

      // Draw letter "L" using rectangles
      canvas.drawRect(const ui.Rect.fromLTWH(35, 25, 8, 35), letterPaint);
      canvas.drawRect(const ui.Rect.fromLTWH(35, 52, 20, 8), letterPaint);
    } else if (assetPath.contains('signature')) {
      // Create a signature placeholder
      final paint = ui.Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = ui.PaintingStyle.stroke;

      final path = ui.Path();
      path.moveTo(10, 50);
      path.quadraticBezierTo(30, 20, 50, 40);
      path.quadraticBezierTo(70, 60, 90, 30);
      path.quadraticBezierTo(110, 10, 140, 45);
      canvas.drawPath(path, paint);
    } else if (assetPath.contains('seal')) {
      // Create an official seal placeholder
      final paint = ui.Paint()
        ..color = const Color(0xFF1565C0)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3;

      // Outer circle
      canvas.drawCircle(const ui.Offset(50, 50), 45, paint);

      // Inner circle
      canvas.drawCircle(const ui.Offset(50, 50), 30, paint);

      // Star shape in center
      final starPaint = ui.Paint()
        ..color = const Color(0xFF1565C0)
        ..style = ui.PaintingStyle.fill;

      final starPath = ui.Path();
      const center = ui.Offset(50, 50);
      const outerRadius = 15.0;
      const innerRadius = 7.0;

      for (int i = 0; i < 10; i++) {
        final angle = (i * math.pi) / 5;
        final radius = i.isEven ? outerRadius : innerRadius;
        final x = center.dx + radius * math.cos(angle - math.pi / 2);
        final y = center.dy + radius * math.sin(angle - math.pi / 2);

        if (i == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, starPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (imgBytes == null) {
      throw Exception('Failed to create image for $assetPath');
    }

    return pw.MemoryImage(imgBytes.buffer.asUint8List());
  }

  // Generate QR code for certificate verification
  static Future<pw.ImageProvider> _generateQRCode(
      String certificateNumber) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Simple QR code placeholder (in real implementation, use qr_flutter package)
    final paint = ui.Paint()
      ..color = Colors.black
      ..style = ui.PaintingStyle.fill;

    // Create a simple pattern resembling QR code
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        if ((i + j) % 2 == 0 || (i * j) % 3 == 0) {
          canvas.drawRect(
            ui.Rect.fromLTWH(i * 10.0, j * 10.0, 8, 8),
            paint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (imgBytes == null) {
      throw Exception('Failed to create QR code');
    }

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
