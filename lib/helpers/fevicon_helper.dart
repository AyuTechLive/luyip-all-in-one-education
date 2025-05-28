import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class FaviconHelper {
  /// Updates the favicon and apple touch icon dynamically
  static void updateFavicon(String logoUrl) {
    if (kIsWeb && logoUrl.isNotEmpty) {
      try {
        // Update favicon
        final favicon =
            html.document.getElementById('favicon') as html.LinkElement?;
        if (favicon != null) {
          favicon.href = logoUrl;
        }

        // Update apple touch icon
        final appleTouchIcon = html.document.getElementById('apple-touch-icon')
            as html.LinkElement?;
        if (appleTouchIcon != null) {
          appleTouchIcon.href = logoUrl;
        }

        // Update any other favicon references
        final faviconElements =
            html.document.querySelectorAll('link[rel*="icon"]');
        for (final element in faviconElements) {
          if (element is html.LinkElement) {
            element.href = logoUrl;
          }
        }

        // Also update manifest icons if they exist
        final manifestIcons =
            html.document.querySelectorAll('link[rel="manifest"]');
        for (final element in manifestIcons) {
          if (element is html.LinkElement) {
            // You might want to update manifest.json as well for PWA icons
            print('Manifest found, consider updating PWA icons');
          }
        }

        print('Favicon updated successfully to: $logoUrl');
      } catch (e) {
        print('Error updating favicon: $e');
      }
    }
  }

  /// Updates the page title dynamically
  static void updatePageTitle(String title) {
    if (kIsWeb && title.isNotEmpty) {
      try {
        html.document.title = title;
        print('Page title updated to: $title');
      } catch (e) {
        print('Error updating page title: $e');
      }
    }
  }

  /// Updates both favicon and page title
  static void updateBranding({String? logoUrl, String? title}) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      updateFavicon(logoUrl);
    }
    if (title != null && title.isNotEmpty) {
      updatePageTitle(title);
    }
  }

  /// Create or update a favicon link element
  static void createFaviconLink(String logoUrl,
      {String rel = 'icon', String? id}) {
    if (kIsWeb && logoUrl.isNotEmpty) {
      try {
        final head = html.document.head;
        if (head != null) {
          // Remove existing favicon with same id/rel if it exists
          if (id != null) {
            final existing = html.document.getElementById(id);
            existing?.remove();
          }

          // Create new favicon link
          final link = html.LinkElement()
            ..rel = rel
            ..type = 'image/png'
            ..href = logoUrl;

          if (id != null) {
            link.id = id;
          }

          head.append(link);
          print('Created favicon link for: $logoUrl');
        }
      } catch (e) {
        print('Error creating favicon link: $e');
      }
    }
  }
}

// Update your _HomePageState's _fetchHomePageData method
