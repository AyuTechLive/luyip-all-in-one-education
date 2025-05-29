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
import 'package:qr_flutter/qr_flutter.dart';

class CertificateGenerator {
  // Generate professional certificate PDF with optimized spacing
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

    // Create QR code with verification URL that includes certificate number
    final qrCodeImage =
        await _generateQRCodeWithCertificateId(certificateNumber);

    // Certificate page with optimized dimensions and spacing
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // 842x595 points
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Elegant background with gradient effect
              _buildBackgroundDesign(),

              // Main certificate content - Optimized container
              pw.Container(
                width: 842, // Full width
                height: 595, // Full height
                padding: const pw.EdgeInsets.all(25), // Minimal padding
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Header with logo and institution name
                    _buildCertificateHeader(logoImage, titleFont, bodyFont),

                    // Certificate title with decorative elements
                    _buildCertificateTitle(titleFont, headlineFont),

                    // Student name section
                    _buildStudentNameSection(
                        studentName, headlineFont, lightFont),

                    // Course information
                    _buildCourseSection(courseName, titleFont, bodyFont),

                    // Achievement details
                    _buildAchievementSection(
                        percentageScore, semiBoldFont, bodyFont),

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

              // Decorative borders
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

  // Build certificate header - Optimized size
  static pw.Widget _buildCertificateHeader(
      pw.ImageProvider logoImage, pw.Font titleFont, pw.Font bodyFont) {
    return pw.Container(
      height: 70, // Fixed height
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            height: 50,
            width: 50,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(25),
              border: pw.Border.all(
                color: PdfColor.fromHex('#1565c0'),
                width: 2,
              ),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 23,
              verticalRadius: 23,
              child: pw.Image(logoImage, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'LUIYP EDUCATIONAL INSTITUTE',
                style: pw.TextStyle(
                  font: titleFont,
                  fontSize: 13,
                  color: PdfColor.fromHex('#1565c0'),
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Excellence in Education & Professional Development',
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 8,
                  color: PdfColor.fromHex('#666666'),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build certificate title - Compact design
  static pw.Widget _buildCertificateTitle(
      pw.Font titleFont, pw.Font headlineFont) {
    return pw.Container(
      height: 80, // Fixed height
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // Decorative line
          pw.Container(
            width: 100,
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
          pw.SizedBox(height: 8),

          pw.Text(
            'CERTIFICATE',
            style: pw.TextStyle(
              font: headlineFont,
              fontSize: 24,
              color: PdfColor.fromHex('#1565c0'),
              letterSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'OF COMPLETION',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 14,
              color: PdfColor.fromHex('#37474f'),
              letterSpacing: 2,
            ),
          ),

          pw.SizedBox(height: 8),
          // Decorative line
          pw.Container(
            width: 100,
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
      ),
    );
  }

  // Build student name section - Compact
  static pw.Widget _buildStudentNameSection(
      String studentName, pw.Font headlineFont, pw.Font lightFont) {
    return pw.Container(
      height: 60, // Fixed height
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'This is to certify that',
            style: pw.TextStyle(
              font: lightFont,
              fontSize: 10,
              color: PdfColor.fromHex('#555555'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            studentName.isNotEmpty ? studentName.toUpperCase() : 'STUDENT NAME',
            style: pw.TextStyle(
              font: headlineFont,
              fontSize: 20,
              color: PdfColor.fromHex('#1565c0'),
              letterSpacing: 1.2,
            ),
          ),
          // pw.Container(
          //   padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          //   decoration: pw.BoxDecoration(
          //     border: pw.Border.all(
          //       color: PdfColor.fromHex('#e0e0e0'),
          //       width: 1,
          //     ),
          //     borderRadius: pw.BorderRadius.circular(6),
          //   ),
          //   child: pw.Text(
          //     studentName.isNotEmpty
          //         ? studentName.toUpperCase()
          //         : 'STUDENT NAME',
          //     style: pw.TextStyle(
          //       font: headlineFont,
          //       fontSize: 20,
          //       color: PdfColor.fromHex('#1565c0'),
          //       letterSpacing: 1.2,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Build course section - Compact
  static pw.Widget _buildCourseSection(
      String courseName, pw.Font titleFont, pw.Font bodyFont) {
    return pw.Container(
      height: 55, // Fixed height
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'has successfully completed the comprehensive course',
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 10,
              color: PdfColor.fromHex('#555555'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#f5f5f5'),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(
                color: PdfColor.fromHex('#1565c0'),
                width: 1,
              ),
            ),
            child: pw.Text(
              courseName.isNotEmpty ? courseName : 'Course Name',
              style: pw.TextStyle(
                font: titleFont,
                fontSize: 14,
                color: PdfColor.fromHex('#1565c0'),
                letterSpacing: 0.6,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Build achievement section - Compact
  static pw.Widget _buildAchievementSection(
      double percentageScore, pw.Font semiBoldFont, pw.Font bodyFont) {
    return pw.Container(
      height: 40, // Fixed height
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#e8f5e8'),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(
                color: PdfColor.fromHex('#4caf50'),
                width: 1,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Score: ',
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 9,
                    color: PdfColor.fromHex('#2e7d32'),
                  ),
                ),
                pw.Text(
                  '${percentageScore.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: semiBoldFont,
                    fontSize: 12,
                    color: PdfColor.fromHex('#1b5e20'),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#fff3e0'),
              borderRadius: pw.BorderRadius.circular(12),
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
                fontSize: 9,
                color: PdfColor.fromHex('#e65100'),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build credentials section - Optimized layout

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
            height: 3,
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
            height: 3,
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
            width: 3,
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
            width: 3,
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

  // Generate QR code with verification URL containing certificate number
  static Future<pw.ImageProvider> _generateQRCodeWithCertificateId(
      String certificateNumber) async {
    try {
      // Create verification URL with certificate number pointing to your actual website
      final verificationUrl =
          'https://luiypeducation.com/#/verify?cert=$certificateNumber';

      print('Generating QR code for URL: $verificationUrl'); // Debug log

      // Create QR code widget with verification URL
      final qrValidationResult = QrValidator.validate(
        data: verificationUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;

        // Create a painter for the QR code
        final painter = QrPainter(
          data: verificationUrl,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          color: Colors.black,
          emptyColor: Colors.white,
        );

        // Generate image from QR code
        final picRecorder = ui.PictureRecorder();
        final canvas = ui.Canvas(picRecorder);

        painter.paint(canvas, const Size(200, 200));

        final picture = picRecorder.endRecording();
        final img = await picture.toImage(200, 200);
        final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        if (imgBytes != null) {
          return pw.MemoryImage(imgBytes.buffer.asUint8List());
        }
      }
    } catch (e) {
      print('Error generating QR code: $e');
    }

    // Fallback: Generate QR code pattern with certificate number
    return _generateFallbackQRCode(certificateNumber);
  }

// Fallback QR code generation with certificate data
  static Future<pw.ImageProvider> _generateFallbackQRCode(
      String certificateNumber) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    final bgPaint = ui.Paint()..color = Colors.white;
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 200, 200), bgPaint);

    // Create QR code pattern based on certificate number and verification URL
    final paint = ui.Paint()
      ..color = Colors.black
      ..style = ui.PaintingStyle.fill;

    final verificationData =
        'https://luiypeducation.com/#/verify?cert=$certificateNumber';
    final hash = verificationData.hashCode;

    // Create a pattern based on verification data
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 20; j++) {
        final cellValue = (hash + i * 20 + j) % 4;
        if (cellValue == 0 || cellValue == 2) {
          canvas.drawRect(
            ui.Rect.fromLTWH(i * 10.0, j * 10.0, 9, 9),
            paint,
          );
        }
      }
    }

    // Add corner markers for QR code authenticity
    final cornerPaint = ui.Paint()
      ..color = Colors.black
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top-left corner
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 60, 60), cornerPaint);
    canvas.drawRect(const ui.Rect.fromLTWH(15, 15, 30, 30), cornerPaint);

    // Top-right corner
    canvas.drawRect(const ui.Rect.fromLTWH(140, 0, 60, 60), cornerPaint);
    canvas.drawRect(const ui.Rect.fromLTWH(155, 15, 30, 30), cornerPaint);

    // Bottom-left corner
    canvas.drawRect(const ui.Rect.fromLTWH(0, 140, 60, 60), cornerPaint);
    canvas.drawRect(const ui.Rect.fromLTWH(15, 155, 30, 30), cornerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(200, 200);
    final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (imgBytes == null) {
      throw Exception('Failed to create QR code');
    }

    return pw.MemoryImage(imgBytes.buffer.asUint8List());
  }

// Also update the verification text in your certificate to reflect the correct URL
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
    return pw.Container(
      height: 100, // Fixed height for bottom section
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Date and certificate info
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#e0e0e0'),
                      width: 1,
                    ),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Issue Date:',
                        style: pw.TextStyle(
                          font: lightFont,
                          fontSize: 7,
                          color: PdfColor.fromHex('#666666'),
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        DateFormat('MMMM dd, yyyy').format(issueDate),
                        style: pw.TextStyle(
                          font: semiBoldFont,
                          fontSize: 9,
                          color: PdfColor.fromHex('#333333'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Certificate ID:',
                        style: pw.TextStyle(
                          font: lightFont,
                          fontSize: 7,
                          color: PdfColor.fromHex('#666666'),
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        certificateNumber.isNotEmpty
                            ? certificateNumber
                            : 'CERT-ID-NOT-SET',
                        style: pw.TextStyle(
                          font: bodyFont,
                          fontSize: 7,
                          color: PdfColor.fromHex('#1565c0'),
                        ),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Verify at: https://luiypeducation.com/#/verify', // Updated URL
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 7,
                    color: PdfColor.fromHex('#1565c0'),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 10),

          // Signature section
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  height: 35,
                  width: 100,
                  child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  width: 100,
                  height: 1,
                  color: PdfColor.fromHex('#cccccc'),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  issuerName.isNotEmpty ? issuerName : 'Authorized Signatory',
                  style: pw.TextStyle(
                    font: semiBoldFont,
                    fontSize: 8,
                    color: PdfColor.fromHex('#333333'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(
                    font: lightFont,
                    fontSize: 7,
                    color: PdfColor.fromHex('#666666'),
                  ),
                ),
                pw.Text(
                  'LUYIP Educational Institute',
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 6,
                    color: PdfColor.fromHex('#666666'),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 10),

          // Seal and QR code
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      height: 45,
                      width: 45,
                      child: pw.Image(sealImage, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      height: 40,
                      width: 40,
                      child: pw.Image(qrCodeImage, fit: pw.BoxFit.contain),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Scan to Verify Certificate',
                  style: pw.TextStyle(
                    font: lightFont,
                    fontSize: 6,
                    color: PdfColor.fromHex('#666666'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      // Debug: Print values being passed
      print('Generating certificate with:');
      print('Student Name: $studentName');
      print('Course Name: $courseName');
      print('Certificate Number: $certificateNumber');
      print('Percentage Score: $percentageScore');

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
