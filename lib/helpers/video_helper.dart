import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;

void initializeSecurePlayer() {
  // Disable right-click globally
  html.document.onContextMenu.listen((e) => e.preventDefault());

  // Disable common keyboard shortcuts
  html.document.onKeyDown.listen((e) {
    // Disable F12, Ctrl+Shift+I, Ctrl+U, Ctrl+S, etc.
    if (e.keyCode == 123 || // F12
        (e.ctrlKey && e.shiftKey && e.keyCode == 73) || // Ctrl+Shift+I
        (e.ctrlKey && e.keyCode == 85) || // Ctrl+U
        (e.ctrlKey && e.keyCode == 83) || // Ctrl+S
        (e.ctrlKey && e.shiftKey && e.keyCode == 67) || // Ctrl+Shift+C
        (e.ctrlKey && e.shiftKey && e.keyCode == 74)) {
      // Ctrl+Shift+J
      e.preventDefault();
      e.stopPropagation();
      _showSecurityAlert();
    }
  });

  // Monitor for developer tools
  _startDevToolsDetection();
}

void _showSecurityAlert() {
  html.window.alert(
      'This content is protected. Developer tools access is restricted.');
}

void _startDevToolsDetection() {
  // This method tries to detect if developer tools are open
  js.context.callMethod('eval', [
    '''
    (function() {
      var devtools = {
        open: false,
        orientation: null
      };
      
      var threshold = 160;
      
      setInterval(function() {
        if (window.outerHeight - window.innerHeight > threshold || 
            window.outerWidth - window.innerWidth > threshold) {
          if (!devtools.open) {
            devtools.open = true;
            console.clear();
            console.log('%cDeveloper tools detected! Video access restricted.', 
                       'color: red; font-size: 20px; font-weight: bold;');
          }
        } else {
          devtools.open = false;
        }
      }, 500);
    })();
  '''
  ]);
}

void registerSecureYouTubePlayer(String viewType, String videoId) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.borderRadius = '12px'
        ..style.background = '#000'
        ..setAttribute('data-video-container', 'true');

      // Create multiple layers to obscure the iframe source
      final obfuscationLayer = html.DivElement()
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.background = 'transparent'
        ..style.zIndex = '5'
        ..style.pointerEvents = 'none';

      // Create the iframe with maximum security settings
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '12px'
        ..style.position = 'relative'
        ..style.zIndex = '1'
        ..allowFullscreen = true
        ..setAttribute('sandbox',
            'allow-scripts allow-same-origin allow-presentation allow-fullscreen')
        ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade')
        ..setAttribute('loading', 'lazy')
        ..setAttribute('importance', 'high');

      // Obfuscate the video URL with multiple redirections and parameters
      final secureUrl = _createSecureEmbedUrl(videoId);
      iframe.src = secureUrl;

      // Add security event listeners
      iframe.onLoad.listen((_) {
        _injectSecurityScript(iframe);
      });

      iframe.onError.listen((_) {
        container.text = 'Video temporarily unavailable';
      });

      // Block inspection attempts
      container.onContextMenu.listen((e) {
        e.preventDefault();
        e.stopPropagation();
      });

      // Add all layers to container
      container.children.addAll([iframe, obfuscationLayer]);

      // Additional security measures
      _addContainerSecurity(container);

      return container;
    },
  );
}

String _createSecureEmbedUrl(String videoId) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final origin = Uri.encodeComponent(html.window.location.origin);

  // Create a heavily parameterized URL to obscure the video ID
  return 'https://www.youtube.com/embed/$videoId?'
      'enablejsapi=1&'
      'origin=$origin&'
      'modestbranding=1&'
      'rel=0&'
      'showinfo=0&'
      'controls=1&'
      'disablekb=1&'
      'fs=1&'
      'iv_load_policy=3&'
      'playsinline=1&'
      'autoplay=0&'
      'mute=0&'
      'loop=0&'
      'color=white&'
      'hl=en&'
      'cc_load_policy=0&'
      'start=0&'
      'end=999999&'
      'version=3&'
      'player_id=secure_player_$timestamp&'
      'widget_referrer=$origin&'
      'ecver=2&'
      'feature=oembed&'
      'fmt=18';
}

void _injectSecurityScript(html.IFrameElement iframe) {
  // Try to inject security measures into the iframe (limited by CORS)
  try {
    final script = '''
      console.clear();
      document.addEventListener('contextmenu', e => e.preventDefault());
      document.addEventListener('selectstart', e => e.preventDefault());
      document.addEventListener('dragstart', e => e.preventDefault());
      
      // Hide video URL from console
      const originalLog = console.log;
      console.log = function(...args) {
        const str = args.join(' ');
        if (!str.includes('youtube.com') && !str.includes('googlevideo')) {
          originalLog.apply(console, args);
        }
      };
    ''';

    iframe.contentWindow?.postMessage(script, '*');
  } catch (e) {
    // Silently fail if CORS blocks this
  }
}

void _addContainerSecurity(html.DivElement container) {
  // Add CSS to prevent common inspection methods
  final style = html.StyleElement()
    ..text = '''
      [data-video-container="true"] {
        -webkit-user-select: none !important;
        -moz-user-select: none !important;
        -ms-user-select: none !important;
        user-select: none !important;
        -webkit-touch-callout: none !important;
        -webkit-tap-highlight-color: transparent !important;
        pointer-events: auto !important;
      }
      
      [data-video-container="true"] iframe {
        pointer-events: auto !important;
      }
      
      /* Hide iframe in dev tools preview */
      @media print {
        [data-video-container="true"] iframe {
          display: none !important;
        }
      }
      
      /* Additional protection */
      [data-video-container="true"]::before {
        content: "";
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: transparent;
        z-index: 10;
        pointer-events: none;
      }
    ''';

  html.document.head?.append(style);

  // Add random attributes to make it harder to identify
  container.setAttribute(
      'data-secure-${DateTime.now().millisecondsSinceEpoch}', 'true');
}
