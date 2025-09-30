import 'package:flutter/material.dart';

class TextFormatter {
  static Widget formatMarkdown(String text, {TextStyle? baseStyle}) {
    return RichText(
      text: _parseMarkdown(text, baseStyle ?? const TextStyle()),
    );
  }

  static TextSpan _parseMarkdown(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicPattern = RegExp(r'\*(.*?)\*');
    
    String remainingText = text;
    int currentIndex = 0;

    while (currentIndex < remainingText.length) {
      // Find the next bold or italic pattern
      final boldMatch = boldPattern.firstMatch(remainingText.substring(currentIndex));
      final italicMatch = italicPattern.firstMatch(remainingText.substring(currentIndex));
      
      Match? nextMatch;
      bool isBold = false;
      
      if (boldMatch != null && italicMatch != null) {
        if (boldMatch.start < italicMatch.start) {
          nextMatch = boldMatch;
          isBold = true;
        } else {
          nextMatch = italicMatch;
          isBold = false;
        }
      } else if (boldMatch != null) {
        nextMatch = boldMatch;
        isBold = true;
      } else if (italicMatch != null) {
        nextMatch = italicMatch;
        isBold = false;
      }

      if (nextMatch != null) {
        // Add text before the match
        if (nextMatch.start > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(currentIndex, currentIndex + nextMatch.start),
            style: baseStyle,
          ));
        }

        // Add the formatted text
        final matchedText = nextMatch.group(1) ?? '';
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
            fontStyle: !isBold ? FontStyle.italic : baseStyle.fontStyle,
          ),
        ));

        // Move past this match
        currentIndex += nextMatch.end;
      } else {
        // No more matches, add remaining text
        spans.add(TextSpan(
          text: remainingText.substring(currentIndex),
          style: baseStyle,
        ));
        break;
      }
    }

    return TextSpan(children: spans);
  }

  static Widget formatSimpleMarkdown(String text, {TextStyle? style}) {
    final baseStyle = style ?? const TextStyle(
      fontSize: 14,
      color: Colors.black87,
      height: 1.4,
    );

    // Handle simple bold formatting **text**
    if (text.contains('**')) {
      return _buildFormattedText(text, baseStyle);
    }

    return Text(text, style: baseStyle);
  }

  static Widget _buildFormattedText(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    
    int lastIndex = 0;
    
    for (final match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      
      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      
      lastIndex = match.end;
    }
    
    // Add any remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}