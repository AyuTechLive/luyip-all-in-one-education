import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class EmailTestPage extends StatefulWidget {
  const EmailTestPage({Key? key}) : super(key: key);

  @override
  State<EmailTestPage> createState() => _EmailTestPageState();
}

class _EmailTestPageState extends State<EmailTestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _testEmailController = TextEditingController();
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isLoading = false;
  String _lastTestResult = '';
  Color _resultColor = Colors.grey;
  String _selectedProvider = 'EmailJS';

  final List<String> _emailProviders = [
    'EmailJS',
    'SendGrid API',
    'Mailgun API',
    'Manual SMTP Test'
  ];

  @override
  void dispose() {
    _testEmailController.dispose();
    _testNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmailViaEmailJS() async {
    // EmailJS is a popular web-based email service that works with Flutter web
    try {
      setState(() {
        _lastTestResult = 'Testing EmailJS connection...';
        _resultColor = Colors.blue;
      });

      // This is a mock test - you'll need to configure EmailJS properly
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id':
              'your_service_id', // Replace with your EmailJS service ID
          'template_id':
              'your_template_id', // Replace with your EmailJS template ID
          'user_id': _apiKeyController.text.trim().isEmpty
              ? 'your_user_id'
              : _apiKeyController.text
                  .trim(), // Replace with your EmailJS user ID
          'template_params': {
            'to_email': _testEmailController.text.trim(),
            'to_name': _testNameController.text.trim().isEmpty
                ? 'Tester'
                : _testNameController.text.trim(),
            'from_name': 'Your Company Test',
            'message':
                'This is a test email to verify email configuration is working.',
            'test_date': DateTime.now().toString(),
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _lastTestResult =
              '✅ EmailJS test successful!\n\nResponse: ${response.body}';
          _resultColor = Colors.green;
        });
        _showSuccessDialog();
      } else {
        throw Exception(
            'EmailJS responded with status ${response.statusCode}: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _lastTestResult =
            '❌ EmailJS test failed!\n\nError: $error\n\nNote: You need to configure EmailJS with your actual service details.';
        _resultColor = Colors.red;
      });
      _showErrorDialog(error.toString());
    }
  }

  Future<void> _sendTestEmailViaSendGrid() async {
    try {
      setState(() {
        _lastTestResult = 'Testing SendGrid API connection...';
        _resultColor = Colors.blue;
      });

      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer ${_apiKeyController.text.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {
                  'email': _testEmailController.text.trim(),
                  'name': _testNameController.text.trim().isEmpty
                      ? 'Tester'
                      : _testNameController.text.trim(),
                }
              ],
              'subject': 'Test Email - SendGrid Configuration Test'
            }
          ],
          'from': {
            'email':
                'your-verified-sender@yourdomain.com', // Replace with your verified sender
            'name': 'Your Company Test'
          },
          'content': [
            {
              'type': 'text/html',
              'value': '''
                <h2>✅ SendGrid Email Test Successful!</h2>
                <p>Hello ${_testNameController.text.trim().isEmpty ? 'Tester' : _testNameController.text.trim()},</p>
                <p>This is a test email sent via SendGrid API to verify your email configuration.</p>
                <p><strong>Test Details:</strong></p>
                <ul>
                  <li>Test Date: ${DateTime.now()}</li>
                  <li>Recipient: ${_testEmailController.text.trim()}</li>
                  <li>Method: SendGrid API</li>
                </ul>
                <p>Your email system is working correctly!</p>
              '''
            }
          ]
        }),
      );

      if (response.statusCode == 202) {
        setState(() {
          _lastTestResult =
              '✅ SendGrid API test successful!\n\nEmail queued for delivery. Status: ${response.statusCode}';
          _resultColor = Colors.green;
        });
        _showSuccessDialog();
      } else {
        throw Exception(
            'SendGrid API responded with status ${response.statusCode}: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _lastTestResult =
            '❌ SendGrid API test failed!\n\nError: $error\n\nMake sure to:\n• Use a valid SendGrid API key\n• Configure a verified sender identity';
        _resultColor = Colors.red;
      });
      _showErrorDialog(error.toString());
    }
  }

  Future<void> _sendTestEmailViaMailgun() async {
    try {
      setState(() {
        _lastTestResult = 'Testing Mailgun API connection...';
        _resultColor = Colors.blue;
      });

      // You'll need to replace 'your-domain' with your actual Mailgun domain
      final response = await http.post(
        Uri.parse(
            'https://api.mailgun.net/v3/your-domain.mailgun.org/messages'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('api:${_apiKeyController.text.trim()}'))}',
        },
        body: {
          'from':
              'Test <test@your-domain.mailgun.org>', // Replace with your domain
          'to': _testEmailController.text.trim(),
          'subject': 'Test Email - Mailgun Configuration Test',
          'html': '''
            <h2>✅ Mailgun Email Test Successful!</h2>
            <p>Hello ${_testNameController.text.trim().isEmpty ? 'Tester' : _testNameController.text.trim()},</p>
            <p>This is a test email sent via Mailgun API to verify your email configuration.</p>
            <p><strong>Test Details:</strong></p>
            <ul>
              <li>Test Date: ${DateTime.now()}</li>
              <li>Recipient: ${_testEmailController.text.trim()}</li>
              <li>Method: Mailgun API</li>
            </ul>
            <p>Your email system is working correctly!</p>
          ''',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _lastTestResult =
              '✅ Mailgun API test successful!\n\nResponse: ${response.body}';
          _resultColor = Colors.green;
        });
        _showSuccessDialog();
      } else {
        throw Exception(
            'Mailgun API responded with status ${response.statusCode}: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _lastTestResult =
            '❌ Mailgun API test failed!\n\nError: $error\n\nMake sure to:\n• Use a valid Mailgun API key\n• Replace domain placeholders with your actual domain';
        _resultColor = Colors.red;
      });
      _showErrorDialog(error.toString());
    }
  }

  Future<void> _testSMTPInfo() async {
    setState(() {
      _lastTestResult = '''
📧 SMTP Direct Connection Test (Information Only)

❌ Socket connections are not supported in Flutter Web or some mobile environments.

Current SMTP Settings:
• Server: smtp.gmail.com:587
• Email: ayushshahi96kmr@gmail.com
• Protocol: TLS/STARTTLS

⚠️ Recommended Solutions:

1. Use EmailJS (Web-friendly):
   • Sign up at emailjs.com
   • Configure email templates
   • Use JavaScript SDK (works in Flutter web)

2. Use SendGrid API:
   • Sign up at sendgrid.com
   • Get API key
   • Use HTTP API calls (works everywhere)

3. Use Mailgun API:
   • Sign up at mailgun.com
   • Get API key
   • Use HTTP API calls (works everywhere)

4. Use Firebase Functions:
   • Create a Cloud Function
   • Send emails server-side
   • Call function from Flutter app

5. For Native Apps Only:
   • Use flutter_email_sender package
   • Opens device email client
   • User sends email manually
      ''';
      _resultColor = Colors.orange;
    });
  }

  Future<void> _sendTestEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      switch (_selectedProvider) {
        case 'EmailJS':
          await _sendTestEmailViaEmailJS();
          break;
        case 'SendGrid API':
          await _sendTestEmailViaSendGrid();
          break;
        case 'Mailgun API':
          await _sendTestEmailViaMailgun();
          break;
        case 'Manual SMTP Test':
          await _testSMTPInfo();
          break;
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Email Test Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Test email sent successfully using $_selectedProvider!'),
            const SizedBox(height: 8),
            Text('📧 Sent to: ${_testEmailController.text.trim()}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Your email configuration is working correctly. You can now integrate this method into your franchise creation feature.',
                style: TextStyle(fontSize: 14, color: Colors.green.shade800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Email Test Failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ Failed to send test email using $_selectedProvider'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  error,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendTestEmail(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Configuration Test'),
        backgroundColor: ColorManager.primary,
        elevation: 0,
      ),
      body: Container(
        color: ColorManager.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: ColorManager.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Configuration Test',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ColorManager.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Test different email services that work with Flutter',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ColorManager.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Socket error explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_outlined, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(
                          'SMTP Socket Issue Detected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The "unsupported socket constructor" error occurs because direct SMTP connections don\'t work in Flutter web or some mobile environments. Use API-based email services instead.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Test form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Email Service to Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email provider dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedProvider,
                        onChanged: (value) =>
                            setState(() => _selectedProvider = value!),
                        decoration: InputDecoration(
                          labelText: 'Email Service Provider',
                          prefixIcon: Icon(Icons.dns_outlined,
                              color: ColorManager.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: ColorManager.primary, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _emailProviders.map((provider) {
                          return DropdownMenuItem(
                            value: provider,
                            child: Text(provider),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      if (_selectedProvider != 'Manual SMTP Test') ...[
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'API Key / User ID',
                            hintText: _selectedProvider == 'EmailJS'
                                ? 'Enter EmailJS User ID'
                                : 'Enter API Key',
                            prefixIcon: Icon(Icons.key_outlined,
                                color: ColorManager.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: ColorManager.primary, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: _selectedProvider == 'Manual SMTP Test'
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'Please enter API key/User ID'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _testEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Test Email Address',
                          hintText: 'Enter email to receive test message',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: ColorManager.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: ColorManager.primary, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true)
                            return 'Please enter email address';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value!)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _testNameController,
                        decoration: InputDecoration(
                          labelText: 'Recipient Name (Optional)',
                          hintText: 'Enter name for personalized test',
                          prefixIcon: Icon(Icons.person_outline,
                              color: ColorManager.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: ColorManager.primary, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendTestEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Testing $_selectedProvider...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Test $_selectedProvider'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Results section
              if (_lastTestResult.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _resultColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _resultColor == Colors.green
                                ? Icons.check_circle
                                : _resultColor == Colors.red
                                    ? Icons.error
                                    : Icons.info,
                            color: _resultColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _resultColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lastTestResult,
                        style: TextStyle(
                          fontSize: 14,
                          color: _resultColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Recommendations section
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Recommended Solutions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. EmailJS: Best for web apps, easy setup\n'
                      '2. SendGrid: Reliable, scalable, great documentation\n'
                      '3. Mailgun: Developer-friendly, good pricing\n'
                      '4. Firebase Functions: Secure, serverless solution',
                      style:
                          TextStyle(fontSize: 14, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
