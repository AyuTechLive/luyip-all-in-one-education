import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:luyip_website_edu/certificate/certificate_model.dart';

class CertificateVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Official website URL for verification
  static const String OFFICIAL_WEBSITE = 'https://education-all-in-one.web.app';
  static const String VERIFICATION_PATH = '/verify';

  /// Verify certificate by certificate number
  Future<CertificateVerificationResult> verifyCertificateByNumber(
    String certificateNumber,
  ) async {
    try {
      // Clean the certificate number
      String cleanCertNumber = certificateNumber.trim().toUpperCase();

      // Check if certificate exists in our database
      final certificateDoc = await _firestore
          .collection('Certificates')
          .doc(cleanCertNumber)
          .get();

      if (!certificateDoc.exists) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'Certificate not found in our database. This certificate may be fake.',
          certificate: null,
        );
      }

      final certificate = Certificate.fromDocSnapshot(certificateDoc);

      // Additional verification checks
      final verificationChecks = await _performSecurityChecks(certificate);

      if (!verificationChecks.isValid) {
        return verificationChecks;
      }

      return CertificateVerificationResult(
        isValid: true,
        certificate: certificate,
        verificationDetails: _generateVerificationDetails(certificate),
      );
    } catch (e) {
      return CertificateVerificationResult(
        isValid: false,
        errorMessage: 'Error during verification: ${e.toString()}',
        certificate: null,
      );
    }
  }

  /// Verify certificate by file analysis
  Future<CertificateVerificationResult> verifyCertificateByFile(
    Uint8List fileBytes,
    String fileName,
    String fileExtension,
  ) async {
    try {
      // Extract certificate information from file
      String? extractedCertNumber;

      if (fileExtension.toLowerCase() == 'pdf') {
        extractedCertNumber = await _extractCertificateNumberFromPDF(
          fileBytes,
          fileName,
        );
      } else {
        // For image files, we could implement OCR in the future
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'Image verification not yet supported. Please use PDF certificates or enter certificate number manually.',
          certificate: null,
        );
      }

      if (extractedCertNumber == null) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'Could not extract certificate number from file. Please verify manually.',
          certificate: null,
        );
      }

      // Verify the extracted certificate number
      final verificationResult =
          await verifyCertificateByNumber(extractedCertNumber);

      if (verificationResult.isValid) {
        // Additional file integrity checks
        final fileIntegrityCheck = await _verifyFileIntegrity(
          fileBytes,
          verificationResult.certificate!,
        );

        if (!fileIntegrityCheck) {
          return CertificateVerificationResult(
            isValid: false,
            errorMessage:
                'File integrity check failed. The uploaded file may have been modified.',
            certificate: null,
          );
        }
      }

      return verificationResult;
    } catch (e) {
      return CertificateVerificationResult(
        isValid: false,
        errorMessage: 'Error processing file: ${e.toString()}',
        certificate: null,
      );
    }
  }

  /// Verify QR code URL format
  Future<CertificateVerificationResult> verifyQRCodeUrl(String qrUrl) async {
    try {
      final uri = Uri.parse(qrUrl);

      // Check if URL is from our official website
      if (!_isOfficialVerificationUrl(uri)) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'QR code does not contain official verification URL. This may be a fake certificate.',
          certificate: null,
        );
      }

      // Extract certificate number from URL
      final certificateNumber = uri.queryParameters['cert'];

      if (certificateNumber == null || certificateNumber.isEmpty) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'Invalid QR code format. Certificate number not found in URL.',
          certificate: null,
        );
      }

      // Verify the certificate number
      return await verifyCertificateByNumber(certificateNumber);
    } catch (e) {
      return CertificateVerificationResult(
        isValid: false,
        errorMessage: 'Invalid QR code URL format: ${e.toString()}',
        certificate: null,
      );
    }
  }

  /// Perform comprehensive security checks on certificate
  Future<CertificateVerificationResult> _performSecurityChecks(
    Certificate certificate,
  ) async {
    try {
      // Check certificate status
      if (certificate.status.toLowerCase() != 'issued') {
        String statusMessage = certificate.status.toLowerCase() == 'revoked'
            ? 'This certificate has been revoked and is no longer valid.'
            : 'This certificate has an invalid status.';

        return CertificateVerificationResult(
          isValid: false,
          errorMessage: statusMessage,
          certificate: certificate,
        );
      }

      // Check if certificate is not too old (optional business rule)
      final daysSinceIssue =
          DateTime.now().difference(certificate.issueDate).inDays;
      if (daysSinceIssue > 3650) {
        // 10 years
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'This certificate is very old and may no longer be valid.',
          certificate: certificate,
        );
      }

      // Verify certificate number format
      if (!_isValidCertificateNumberFormat(certificate.certificateNumber)) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage: 'Certificate number format is invalid.',
          certificate: certificate,
        );
      }

      // Check if the issuer is authorized
      if (!await _isAuthorizedIssuer(certificate.issuedBy)) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'Certificate was not issued by an authorized instructor.',
          certificate: certificate,
        );
      }

      // Verify course existence
      if (!await _courseExists(certificate.courseName)) {
        return CertificateVerificationResult(
          isValid: false,
          errorMessage:
              'The course specified in this certificate does not exist in our system.',
          certificate: certificate,
        );
      }

      return CertificateVerificationResult(
        isValid: true,
        certificate: certificate,
      );
    } catch (e) {
      return CertificateVerificationResult(
        isValid: false,
        errorMessage: 'Error during security checks: ${e.toString()}',
        certificate: certificate,
      );
    }
  }

  /// Extract certificate number from PDF file
  Future<String?> _extractCertificateNumberFromPDF(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      // First, try to extract from filename
      RegExp certPattern = RegExp(r'CERT-[A-Z0-9-]+');
      Match? match = certPattern.firstMatch(fileName.toUpperCase());

      if (match != null) {
        return match.group(0);
      }

      // TODO: Implement actual PDF text extraction
      // For now, we'll return null if not found in filename
      // In a real implementation, you would use a PDF parsing library
      // to extract text and search for the certificate number pattern

      return null;
    } catch (e) {
      print('Error extracting certificate number from PDF: $e');
      return null;
    }
  }

  /// Verify file integrity against stored certificate
  Future<bool> _verifyFileIntegrity(
    Uint8List fileBytes,
    Certificate certificate,
  ) async {
    try {
      // Generate hash of uploaded file
      final uploadedFileHash = sha256.convert(fileBytes).toString();

      // TODO: In a real implementation, you would store the hash of the original
      // certificate file when it's generated and compare it here
      // For now, we'll assume integrity is valid if we found the certificate

      return true;
    } catch (e) {
      print('Error verifying file integrity: $e');
      return false;
    }
  }

  /// Check if URL is from official verification endpoint
  bool _isOfficialVerificationUrl(Uri uri) {
    return uri.scheme == 'https' &&
        uri.host == Uri.parse(OFFICIAL_WEBSITE).host &&
        uri.path == VERIFICATION_PATH;
  }

  /// Validate certificate number format
  bool _isValidCertificateNumberFormat(String certificateNumber) {
    // Expected format: CERT-XXX-USERID-TIMESTAMP
    final pattern = RegExp(r'^CERT-[A-Z]{1,5}-[A-Za-z0-9]+(-\d+)?');
    return pattern.hasMatch(certificateNumber);
  }

  /// Check if issuer is authorized
  Future<bool> _isAuthorizedIssuer(String issuerEmail) async {
    try {
      // Check if issuer exists in authorized users collection
      final issuerQuery = await _firestore
          .collection('Users')
          .where('Email', isEqualTo: issuerEmail)
          .where('Role', whereIn: ['admin', 'instructor', 'teacher'])
          .limit(1)
          .get();

      return issuerQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking issuer authorization: $e');
      return false;
    }
  }

  /// Check if course exists in system
  Future<bool> _courseExists(String courseName) async {
    try {
      final courseDoc =
          await _firestore.collection('All Courses').doc(courseName).get();

      return courseDoc.exists;
    } catch (e) {
      print('Error checking course existence: $e');
      return false;
    }
  }

  /// Generate detailed verification information
  Map<String, dynamic> _generateVerificationDetails(Certificate certificate) {
    return {
      'verificationTime': DateTime.now().toIso8601String(),
      'certificateAge': DateTime.now().difference(certificate.issueDate).inDays,
      'verificationMethod': 'Database lookup',
      'securityChecks': [
        'Certificate exists in database',
        'Certificate status is valid',
        'Issuer is authorized',
        'Course exists in system',
        'Certificate number format is valid',
      ],
      'verificationId': _generateVerificationId(certificate.certificateNumber),
    };
  }

  /// Generate unique verification ID for this verification attempt
  String _generateVerificationId(String certificateNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final combined = '$certificateNumber-$timestamp';
    return sha256.convert(utf8.encode(combined)).toString().substring(0, 16);
  }

  /// Get verification statistics
  Future<Map<String, dynamic>> getVerificationStatistics() async {
    try {
      final certificatesSnapshot = await _firestore
          .collection('Certificates')
          .where('status', isEqualTo: 'issued')
          .get();

      final totalCertificates = certificatesSnapshot.docs.length;

      // Get certificates issued in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentCertificates = certificatesSnapshot.docs.where((doc) {
        final certificate = Certificate.fromDocSnapshot(doc);
        return certificate.issueDate.isAfter(thirtyDaysAgo);
      }).length;

      return {
        'totalIssuedCertificates': totalCertificates,
        'recentCertificates': recentCertificates,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Unable to fetch statistics: ${e.toString()}',
      };
    }
  }
}

/// Result of certificate verification
class CertificateVerificationResult {
  final bool isValid;
  final Certificate? certificate;
  final String? errorMessage;
  final Map<String, dynamic>? verificationDetails;

  CertificateVerificationResult({
    required this.isValid,
    this.certificate,
    this.errorMessage,
    this.verificationDetails,
  });

  /// Convert to map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'certificate': certificate?.toMap(),
      'errorMessage': errorMessage,
      'verificationDetails': verificationDetails,
    };
  }
}
