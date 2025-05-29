import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:intl/intl.dart';
import 'package:luyip_website_edu/certificate/certificate_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class CertificateVerificationPage extends StatefulWidget {
  final String? certificateNumber; // For QR code scans

  const CertificateVerificationPage({
    super.key,
    this.certificateNumber,
  });

  @override
  State<CertificateVerificationPage> createState() =>
      _CertificateVerificationPageState();
}

class _CertificateVerificationPageState
    extends State<CertificateVerificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _certificateNumberController =
      TextEditingController();

  // State variables
  bool _isVerifying = false;
  Certificate? _verifiedCertificate;
  String? _verificationError;
  int _selectedVerificationMethod = 0;
  Uint8List? _uploadedFile;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // If coming from QR code scan, pre-fill certificate number
    if (widget.certificateNumber != null) {
      _certificateNumberController.text = widget.certificateNumber!;
      _selectedVerificationMethod = 1;
      _tabController.animateTo(1);
      // Auto-verify if certificate number is provided
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
      Utils().toastMessage('Please enter a certificate number');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _verifiedCertificate = null;
    });

    try {
      final certificateDoc = await _firestore
          .collection('Certificates')
          .doc(_certificateNumberController.text.trim())
          .get();

      if (!certificateDoc.exists) {
        setState(() {
          _verificationError = 'Certificate not found in our database';
        });
        return;
      }

      final certificate = Certificate.fromDocSnapshot(certificateDoc);

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

      Utils().toastMessage('Certificate verified successfully!');
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

  Future<void> _uploadAndVerifyCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _uploadedFile = result.files.single.bytes;
          _uploadedFileName = result.files.single.name;
        });

        // Extract certificate number from file name or metadata
        String? extractedCertNumber =
            _extractCertificateNumber(_uploadedFileName!);

        if (extractedCertNumber != null) {
          _certificateNumberController.text = extractedCertNumber;
          await _verifyCertificateByNumber();
        } else {
          Utils().toastMessage(
              'Could not extract certificate number from file. Please enter manually.');
        }
      }
    } catch (e) {
      Utils().toastMessage('Error uploading file: ${e.toString()}');
    }
  }

  String? _extractCertificateNumber(String fileName) {
    // Try to extract certificate number from filename
    // Assuming format like "CERT-XXX-USERID-TIMESTAMP.pdf"
    RegExp certPattern = RegExp(r'CERT-[A-Z0-9]+-[A-Za-z0-9]+-\d+');
    Match? match = certPattern.firstMatch(fileName);
    return match?.group(0);
  }

  // Future<void> _scanQRCode() async {
  //   try {
  //     // Navigate to QR scanner page
  //     final result = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const QRScannerPage(),
  //       ),
  //     );

  //     if (result != null) {
  //       // Extract certificate number from QR code URL
  //       String? certNumber = _extractCertFromQRUrl(result);
  //       if (certNumber != null) {
  //         _certificateNumberController.text = certNumber;
  //         await _verifyCertificateByNumber();
  //       } else {
  //         Utils().toastMessage('Invalid QR code format');
  //       }
  //     }
  //   } catch (e) {
  //     Utils().toastMessage('Error scanning QR code: ${e.toString()}');
  //   }
  // }

  String? _extractCertFromQRUrl(String qrData) {
    // Extract certificate number from URL like "https://luyip.edu/verify?cert=CERT-XXX-USERID-TIMESTAMP"
    Uri? uri = Uri.tryParse(qrData);
    if (uri != null && uri.queryParameters.containsKey('cert')) {
      return uri.queryParameters['cert'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('Certificate Verification'),
        backgroundColor: Colors.white,
        foregroundColor: ColorManager.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isSmallScreen),
            _buildTabBar(isSmallScreen),
            _buildTabContent(isSmallScreen),
            if (_verifiedCertificate != null || _verificationError != null)
              _buildVerificationResult(isSmallScreen),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
        children: [
          Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              size: isSmallScreen ? 30 : 40,
              color: ColorManager.primary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Verify Certificate Authenticity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Verify if a certificate is genuine and issued by LUYIP Educational Institute',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorManager.textMedium,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorManager.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: ColorManager.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Official verification system for https://luiypeducation.com/',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: ColorManager.success,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTabBar(bool isSmallScreen) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedVerificationMethod = index;
            _verificationError = null;
            _verifiedCertificate = null;
          });
        },
        labelColor: ColorManager.primary,
        unselectedLabelColor: ColorManager.textMedium,
        indicatorColor: ColorManager.primary,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 10 : 12),
        isScrollable: isSmallScreen,
        tabs: const [
          Tab(
            icon: Icon(Icons.upload_file),
            text: 'Upload Certificate',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Certificate Number',
          ),
          // Tab(
          //   icon: Icon(Icons.qr_code_scanner),
          //   text: 'Scan QR Code',
          // ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isSmallScreen) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: IndexedStack(
        index: _selectedVerificationMethod,
        children: [
          _buildUploadTab(isSmallScreen),
          _buildSearchTab(isSmallScreen),
          // _buildQRTab(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildUploadTab(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: isSmallScreen ? 48 : 64,
                  color: ColorManager.primary,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Upload Certificate File',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Upload PDF, JPG, or PNG file of your certificate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textMedium,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                if (_uploadedFileName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorManager.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.file_present, color: ColorManager.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _uploadedFileName!,
                            style: TextStyle(
                              color: ColorManager.success,
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isVerifying ? null : _uploadAndVerifyCertificate,
                    icon: _isVerifying
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isVerifying ? 'Verifying...' : 'Choose File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 24 : 32,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildSearchTab(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: isSmallScreen ? 48 : 64,
                  color: ColorManager.primary,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Enter Certificate Number',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Enter the certificate ID to verify its authenticity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textMedium,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                TextField(
                  controller: _certificateNumberController,
                  decoration: InputDecoration(
                    labelText: 'Certificate Number',
                    hintText: 'e.g., CERT-ABC-12345-1234567890',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: ColorManager.primary),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isVerifying ? null : _verifyCertificateByNumber,
                    icon: _isVerifying
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.verified),
                    label: Text(
                        _isVerifying ? 'Verifying...' : 'Verify Certificate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  // Widget _buildQRTab(bool isSmallScreen) {
  //   return Padding(
  //     padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         SizedBox(height: isSmallScreen ? 16 : 20),
  //         Container(
  //           padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: Colors.grey.shade300),
  //           ),
  //           child: Column(
  //             children: [
  //               Icon(
  //                 Icons.qr_code_scanner,
  //                 size: isSmallScreen ? 48 : 64,
  //                 color: ColorManager.primary,
  //               ),
  //               SizedBox(height: isSmallScreen ? 12 : 16),
  //               Text(
  //                 'Scan QR Code',
  //                 style: TextStyle(
  //                   fontSize: isSmallScreen ? 16 : 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: ColorManager.textDark,
  //                 ),
  //               ),
  //               SizedBox(height: isSmallScreen ? 6 : 8),
  //               Text(
  //                 'Scan the QR code printed on your certificate',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   color: ColorManager.textMedium,
  //                   fontSize: isSmallScreen ? 12 : 14,
  //                 ),
  //               ),
  //               SizedBox(height: isSmallScreen ? 16 : 20),
  //               Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: ColorManager.info.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(8),
  //                   border:
  //                       Border.all(color: ColorManager.info.withOpacity(0.3)),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.info_outline, color: ColorManager.info),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Text(
  //                         'Look for the QR code on the bottom right corner of your certificate',
  //                         style: TextStyle(
  //                           color: ColorManager.info,
  //                           fontSize: isSmallScreen ? 10 : 12,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(height: isSmallScreen ? 16 : 20),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton.icon(
  //                   onPressed: _scanQRCode,
  //                   icon: const Icon(Icons.qr_code_scanner),
  //                   label: const Text('Open QR Scanner'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: ColorManager.primary,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(
  //                         vertical: isSmallScreen ? 12 : 16),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildVerificationResult(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _verificationError != null
          ? _buildErrorResult(isSmallScreen)
          : _buildSuccessResult(isSmallScreen),
    );
  }

  Widget _buildErrorResult(bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: isSmallScreen ? 40 : 48,
          color: ColorManager.error,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          'Verification Failed',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.error,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          _verificationError!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorManager.textMedium,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorManager.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorManager.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: ColorManager.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This certificate is not authentic or not found in our database.',
                  style: TextStyle(
                    color: ColorManager.error,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessResult(bool isSmallScreen) {
    if (_verifiedCertificate == null) return Container();

    return Column(
      children: [
        Icon(
          Icons.verified,
          size: isSmallScreen ? 40 : 48,
          color: ColorManager.success,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          'Certificate Verified ✓',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.success,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          'This certificate is authentic and issued by LUYIP Educational Institute',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorManager.textMedium,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorManager.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildDetailRow('Student Name', _verifiedCertificate!.userName,
                  isSmallScreen),
              _buildDetailRow(
                  'Course', _verifiedCertificate!.courseName, isSmallScreen),
              _buildDetailRow('Certificate ID',
                  _verifiedCertificate!.certificateNumber, isSmallScreen),
              _buildDetailRow(
                  'Issue Date',
                  DateFormat('MMMM dd, yyyy')
                      .format(_verifiedCertificate!.issueDate),
                  isSmallScreen),
              _buildDetailRow(
                  'Score',
                  '${_verifiedCertificate!.percentageScore.toStringAsFixed(1)}%',
                  isSmallScreen),
              _buildDetailRow(
                  'Issued By', _verifiedCertificate!.issuedBy, isSmallScreen),
              _buildDetailRow('Status',
                  _verifiedCertificate!.status.toUpperCase(), isSmallScreen),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_verifiedCertificate!.certificateUrl.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _viewCertificate(_verifiedCertificate!.certificateUrl),
              icon: const Icon(Icons.visibility),
              label: const Text('View Original Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ColorManager.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorManager.textDark,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            )
          : Row(
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
                const Text(': '),
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

  Future<void> _viewCertificate(String certificateUrl) async {
    try {
      final url = Uri.parse(certificateUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        Utils().toastMessage('Could not open certificate URL');
      }
    } catch (e) {
      Utils().toastMessage('Error opening certificate: ${e.toString()}');
    }
  }
}

// QR Scanner Page
// class QRScannerPage extends StatefulWidget {
//   const QRScannerPage({super.key});

//   @override
//   State<QRScannerPage> createState() => _QRScannerPageState();
// }

// class _QRScannerPageState extends State<QRScannerPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Scan QR Code'),
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 5,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//               overlay: QrScannerOverlayShape(
//                 borderColor: Colors.blue,
//                 borderRadius: 10,
//                 borderLength: 30,
//                 borderWidth: 10,
//                 cutOutSize: 300,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Container(
//               color: Colors.black,
//               child: Center(
//                 child: Text(
//                   'Align the QR code within the frame',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) {
//       controller.pauseCamera();
//       Navigator.pop(context, scanData.code);
//     });
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
