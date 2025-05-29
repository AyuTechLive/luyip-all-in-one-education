import 'package:flutter/material.dart';

import 'package:luyip_website_edu/verification_certificate/certificate_verification_page.dart';

class CertificateVerificationRoute extends StatelessWidget {
  final String? certificateNumber;

  const CertificateVerificationRoute({
    super.key,
    this.certificateNumber,
  });

  @override
  Widget build(BuildContext context) {
    return CertificateVerificationPage(
      certificateNumber: certificateNumber,
    );
  }
}
