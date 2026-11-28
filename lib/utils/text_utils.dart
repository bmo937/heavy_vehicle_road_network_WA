/// Text utility functions for cleaning and formatting text content
class TextUtils {
  /// Removes HTML tags and decodes HTML entities from a string
  static String stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    String text = htmlString;

    // Remove HTML tags using regex
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    // Clean up multiple spaces and trim
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove trailing comma if present
    if (text.endsWith(',')) {
      text = text.substring(0, text.length - 1);
    }

    return text;
  }

  /// Removes HTML tags and preserves basic structure by converting some tags to text equivalents
  static String stripHtmlWithStructure(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    String text = htmlString;

    // Convert list items to bullet points
    /* text = text.replaceAll(RegExp(r'<li[^>]*>'), '• '); */
    text = text.replaceAll(RegExp(r'<li[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'</li>'), '\n');

    // Convert paragraph breaks
    text = text.replaceAll(RegExp(r'<p[^>]*>'), '');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');

    // Convert line breaks
    text = text.replaceAll(RegExp(r'<br[^>]*>'), '\n');

    // Remove all other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    // Clean up excessive whitespace while preserving intentional line breaks
    text = text.replaceAll(
        RegExp(r'[ \t]+'), ' '); // Multiple spaces/tabs to single space
    text = text.replaceAll(
        RegExp(r'\n[ \t]+'), '\n'); // Remove spaces/tabs after newlines
    text = text.replaceAll(
        RegExp(r'[ \t]+\n'), '\n'); // Remove spaces/tabs before newlines
    text = text.replaceAll(
        RegExp(r'\n{3,}'), '\n\n'); // Multiple newlines to double newline
    text = text.trim();

    // Remove trailing comma if present
    if (text.endsWith(',')) {
      text = text.substring(0, text.length - 1);
    }

    return text;
  }
}
