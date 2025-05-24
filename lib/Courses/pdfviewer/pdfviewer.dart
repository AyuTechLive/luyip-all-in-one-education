import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:luyip_website_edu/helpers/colors.dart';
import 'dart:js' as js;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'dart:ui' as ui;

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  late String _viewId;
  String? _pdfBlobUrl;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializePdfViewer();
    }
  }

  Future<void> _initializePdfViewer() async {
    try {
      _viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

      // Try to create blob URL first, fallback to direct URL
      await _createPdfBlob();

      _registerPdfViewer();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('PDF initialization error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  Future<void> _createPdfBlob() async {
    try {
      // First, try to fetch the PDF and create a blob
      final response = await html.HttpRequest.request(
        widget.pdfUrl,
        method: 'GET',
        responseType: 'arraybuffer',
        requestHeaders: {
          'Accept': 'application/pdf,*/*',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.status == 200) {
        final Uint8List bytes = Uint8List.view(response.response as ByteBuffer);
        final html.Blob blob = html.Blob([bytes], 'application/pdf');
        _pdfBlobUrl = html.Url.createObjectUrl(blob);
        print('Created blob URL successfully');
      } else {
        throw Exception('HTTP ${response.status}: ${response.statusText}');
      }
    } catch (e) {
      print('Blob creation failed: $e');
      // Fallback to direct URL
      _pdfBlobUrl = widget.pdfUrl;
      print('Using direct URL as fallback');
    }
  }

  void _registerPdfViewer() {
    if (kIsWeb && _pdfBlobUrl != null) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          final container = html.DivElement()
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = '#ffffff'
            ..style.position = 'relative';

          // Try different PDF embedding methods
          _createPdfEmbed(container);

          return container;
        },
      );
    }
  }

  void _createPdfEmbed(html.DivElement container) {
    // Method 1: Try with embed tag
    final embed = html.EmbedElement()
      ..src = _pdfBlobUrl!
      ..type = 'application/pdf'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';

    // Method 2: Fallback with iframe
    final iframe = html.IFrameElement()
      ..src = _pdfBlobUrl!
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.display = 'none';

    // Method 3: Fallback with object tag
    final object = html.ObjectElement()
      ..data = _pdfBlobUrl!
      ..type = 'application/pdf'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.display = 'none';

    // Loading indicator
    final loadingDiv = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)'
      ..style.fontSize = '16px'
      ..style.color = '#666'
      ..text = 'Loading PDF...';

    // Error message div
    final errorDiv = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)'
      ..style.fontSize = '16px'
      ..style.color = '#d32f2f'
      ..style.textAlign = 'center'
      ..style.display = 'none';

    // Create error message content
    final errorText = html.ParagraphElement()
      ..text = 'Unable to display PDF in browser.'
      ..style.margin = '0 0 10px 0';

    final errorLink = html.AnchorElement(href: _pdfBlobUrl!)
      ..text = 'Click here to open PDF in new tab'
      ..target = '_blank'
      ..style.color = '#1976d2'
      ..style.textDecoration = 'underline';

    errorDiv.append(errorText);
    errorDiv.append(errorLink);

    container.append(loadingDiv);
    container.append(errorDiv);
    container.append(embed);
    container.append(iframe);
    container.append(object);

    // Handle embed load/error
    embed.onLoad.listen((_) {
      loadingDiv.style.display = 'none';
      embed.style.display = 'block';
      print('PDF loaded successfully with embed');
    });

    embed.onError.listen((_) {
      print('Embed failed, trying iframe');
      embed.style.display = 'none';
      iframe.style.display = 'block';

      // If iframe also fails, try object
      Timer(Duration(seconds: 3), () {
        if (iframe.style.display == 'block') {
          iframe.style.display = 'none';
          object.style.display = 'block';

          // If object also fails, show error
          Timer(Duration(seconds: 3), () {
            if (object.style.display == 'block') {
              object.style.display = 'none';
              loadingDiv.style.display = 'none';
              errorDiv.style.display = 'block';
            }
          });
        }
      });
    });

    iframe.onLoad.listen((_) {
      loadingDiv.style.display = 'none';
      print('PDF loaded successfully with iframe');
    });

    object.onLoad.listen((_) {
      loadingDiv.style.display = 'none';
      print('PDF loaded successfully with object');
    });
  }

  Future<void> _downloadPdf() async {
    if (_pdfBlobUrl != null) {
      try {
        final anchor = html.AnchorElement(href: _pdfBlobUrl!)
          ..setAttribute('download', '${widget.title}.pdf')
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${widget.title}.pdf'),
            backgroundColor: ColorManager.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openInNewTab() {
    if (_pdfBlobUrl != null) {
      html.window.open(_pdfBlobUrl!, '_blank');
    }
  }

  @override
  void dispose() {
    // Clean up blob URL
    if (kIsWeb && _pdfBlobUrl != null && _pdfBlobUrl!.startsWith('blob:')) {
      html.Url.revokeObjectUrl(_pdfBlobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text("PDF viewer is only supported on web.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _errorMessage == null) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in new tab',
              onPressed: _openInNewTab,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: _downloadPdf,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initializePdfViewer();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorManager.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(color: ColorManager.textMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we fetch the document',
                    style: TextStyle(
                      color: ColorManager.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: ColorManager.textMedium),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PDF URL: ${widget.pdfUrl}',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _initializePdfViewer();
                            },
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              html.window.open(widget.pdfUrl, '_blank');
                            },
                            child: const Text('Open Direct'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: HtmlElementView(viewType: _viewId),
                ),
    );
  }
}
