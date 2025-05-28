import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:luyip_website_edu/certificate/certificate_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class CertificateVerificationPage extends StatefulWidget {
  final String? certificateNumber; // For QR code verification

  const CertificateVerificationPage({
    super.key,
    this.certificateNumber,
  });

  @override
  State<CertificateVerificationPage> createState() =>
      _CertificateVerificationPageState();
}

class _CertificateVerificationPageState
    extends State<CertificateVerificationPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _certificateNumberController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  bool _isVerifying = false;
  Certificate? _verifiedCertificate;
  String? _verificationError;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // If certificate number is provided (from QR code), verify it automatically
    if (widget.certificateNumber != null) {
      _certificateNumberController.text = widget.certificateNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyCertificateByNumber();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificateByNumber() async {
    if (_certificateNumberController.text.trim().isEmpty) {
      setState(() {
        _verificationError = 'Please enter a certificate number';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _verifiedCertificate = null;
    });

    try {
      final certificateNumber = _certificateNumberController.text.trim();

      // Search for certificate in Firestore
      final certificateDoc = await _firestore
          .collection('Certificates')
          .doc(certificateNumber)
          .get();

      if (certificateDoc.exists) {
        final certificate = Certificate.fromDocSnapshot(certificateDoc);

        // Additional verification checks
        if (certificate.status != 'issued') {
          setState(() {
            _verificationError =
                'This certificate has been revoked or is invalid';
          });
          return;
        }

        setState(() {
          _verifiedCertificate = certificate;
        });
      } else {
        setState(() {
          _verificationError =
              'Certificate not found. This certificate may be fake or invalid.';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = 'Error verifying certificate: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _pickCertificateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _verificationError = null;
          _verifiedCertificate = null;
        });
      }
    } catch (e) {
      Utils().toastMessage('Error selecting file: ${e.toString()}');
    }
  }

  Future<void> _verifyCertificateByFile() async {
    if (_selectedFile == null) {
      setState(() {
        _verificationError = 'Please select a certificate file first';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _verifiedCertificate = null;
    });

    try {
      // Extract certificate information from file
      String? extractedCertNumber;

      if (_selectedFile!.extension?.toLowerCase() == 'pdf') {
        extractedCertNumber = await _extractCertificateNumberFromPDF();
      } else {
        // For image files, we would need OCR - for now, show error
        setState(() {
          _verificationError =
              'Image verification not yet supported. Please use PDF certificates or enter certificate number manually.';
        });
        return;
      }

      if (extractedCertNumber != null) {
        // Verify the extracted certificate number
        _certificateNumberController.text = extractedCertNumber;
        await _verifyCertificateByNumber();
      } else {
        setState(() {
          _verificationError =
              'Could not extract certificate number from file. Please verify manually.';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = 'Error processing file: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<String?> _extractCertificateNumberFromPDF() async {
    try {
      // This is a simplified implementation
      // In a real app, you'd use a PDF text extraction library

      // For now, we'll check if the file name contains a certificate pattern
      String fileName = _selectedFile!.name;

      // Look for CERT- pattern in filename
      RegExp certPattern = RegExp(r'CERT-[A-Z0-9-]+');
      Match? match = certPattern.firstMatch(fileName.toUpperCase());

      if (match != null) {
        return match.group(0);
      }

      // If not found in filename, return null
      // In a real implementation, you'd extract text from PDF content
      return null;
    } catch (e) {
      print('Error extracting certificate number: $e');
      return null;
    }
  }

  void _clearVerification() {
    setState(() {
      _verifiedCertificate = null;
      _verificationError = null;
      _selectedFile = null;
      _certificateNumberController.clear();
    });
  }

  Future<void> _viewOriginalCertificate() async {
    if (_verifiedCertificate?.certificateUrl != null) {
      try {
        final url = Uri.parse(_verifiedCertificate!.certificateUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } catch (e) {
        Utils().toastMessage('Error opening certificate: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('Certificate Verification'),
        backgroundColor: Colors.white,
        foregroundColor: ColorManager.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showVerificationInfo(),
            tooltip: 'Verification Info',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCertificateNumberTab(),
                _buildFileUploadTab(),
                _buildQRScanTab(),
              ],
            ),
          ),
          if (_verifiedCertificate != null || _verificationError != null)
            _buildVerificationResult(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color: ColorManager.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificate Verification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    Text(
                      'Verify the authenticity of LUYIP Educational Institute certificates',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorManager.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: ColorManager.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only certificates issued by LUYIP Educational Institute will show as verified.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorManager.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorManager.primary,
        unselectedLabelColor: ColorManager.textMedium,
        indicatorColor: ColorManager.primary,
        tabs: const [
          Tab(
            icon: Icon(Icons.numbers),
            text: 'Certificate ID',
          ),
          Tab(
            icon: Icon(Icons.upload_file),
            text: 'Upload File',
          ),
          Tab(
            icon: Icon(Icons.qr_code_scanner),
            text: 'QR Code',
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateNumberTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Certificate Number',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the certificate number found on the certificate document',
            style: TextStyle(
              color: ColorManager.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _certificateNumberController,
            decoration: InputDecoration(
              labelText: 'Certificate Number',
              hintText: 'e.g., CERT-ABC-123456-789012',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorManager.primary),
              ),
            ),
            onSubmitted: (_) => _verifyCertificateByNumber(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _verifyCertificateByNumber,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isVerifying ? 'Verifying...' : 'Verify Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Certificate File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a PDF certificate file to verify its authenticity',
            style: TextStyle(
              color: ColorManager.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // File selection area
          GestureDetector(
            onTap: _pickCertificateFile,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFile != null
                      ? ColorManager.primary
                      : ColorManager.textMedium.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedFile != null
                    ? ColorManager.primary.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.description
                        : Icons.cloud_upload,
                    size: 48,
                    color: _selectedFile != null
                        ? ColorManager.primary
                        : ColorManager.textMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.name
                        : 'Click to select certificate file',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedFile != null
                          ? ColorManager.textDark
                          : ColorManager.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Supported formats: PDF, JPG, PNG',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFile == null || _isVerifying
                  ? null
                  : _verifyCertificateByFile,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified),
              label: Text(_isVerifying ? 'Verifying...' : 'Verify Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QR Code Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan the QR code on the certificate or access the verification link',
            style: TextStyle(
              color: ColorManager.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: ColorManager.primary.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: ColorManager.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'QR Code Scanner',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your device camera to scan the QR code on the certificate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textMedium,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement QR scanner
                    Utils().toastMessage('QR Scanner not implemented yet');
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open Camera Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorManager.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: ColorManager.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: ColorManager.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'QR Code contains verification URL',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: ColorManager.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The QR code on genuine certificates contains a link to: https://education-all-in-one.web.app/verify?cert=CERTIFICATE_NUMBER',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _verifiedCertificate != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _verifiedCertificate != null ? Icons.verified : Icons.error,
                  color:
                      _verifiedCertificate != null ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _verifiedCertificate != null
                          ? 'Certificate Verified ✓'
                          : 'Verification Failed ✗',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _verifiedCertificate != null
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (_verificationError != null)
                      Text(
                        _verificationError!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearVerification,
                icon: const Icon(Icons.close),
                tooltip: 'Clear',
              ),
            ],
          ),
          if (_verifiedCertificate != null) ...[
            const SizedBox(height: 20),
            _buildCertificateDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificateDetails() {
    final certificate = _verifiedCertificate!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Student Name', certificate.userName),
        _buildDetailRow('Course', certificate.courseName),
        _buildDetailRow('Certificate ID', certificate.certificateNumber),
        _buildDetailRow('Issue Date',
            DateFormat('dd MMM, yyyy').format(certificate.issueDate)),
        _buildDetailRow('Issued By', certificate.issuedBy),
        _buildDetailRow(
            'Score', '${certificate.percentageScore.toStringAsFixed(1)}%'),
        _buildDetailRow('Status', certificate.status.toUpperCase()),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _viewOriginalCertificate,
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Original'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorManager.primary,
                  side: BorderSide(color: ColorManager.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Utils().toastMessage(
                      'This certificate is genuine and verified!');
                },
                icon: const Icon(Icons.verified),
                label: const Text('Verified'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ColorManager.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ColorManager.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Verification Works'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Our verification system checks:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoPoint('Certificate exists in our database'),
              _buildInfoPoint('Certificate status is valid (not revoked)'),
              _buildInfoPoint('Certificate details match our records'),
              _buildInfoPoint('QR code contains correct verification URL'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorManager.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Only certificates issued by LUYIP Educational Institute will show as verified. Any other certificates are not authentic.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorManager.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: ColorManager.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
