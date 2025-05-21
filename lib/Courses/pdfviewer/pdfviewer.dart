import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:luyip_website_edu/helpers/colors.dart';

/// Required import for platformViewRegistry
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Register unique iframe view
      final viewId = 'pdf-viewer-${pdfUrl.hashCode}';

      // Only register once (avoids duplicates on hot reload)
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        viewId,
        (int _) {
          final iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allowFullscreen = true;
          return iframe;
        },
      );

      return Scaffold(
        appBar: AppBar(
          backgroundColor: ColorManager.primary,
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: () {
                html.AnchorElement(href: pdfUrl)
                  ..setAttribute('download', '$title.pdf')
                  ..click();
              },
            ),
          ],
        ),
        body: HtmlElementView(viewType: viewId),
      );
    } else {
      return const Scaffold(
        body: Center(child: Text("PDF viewer is only supported on web.")),
      );
    }
  }
}
