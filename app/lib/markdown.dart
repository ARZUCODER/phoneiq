import 'package:flutter/material.dart';

class MarkdownText extends StatelessWidget {
  final String data;
  final TextStyle style;

  const MarkdownText(this.data, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final lines = data.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 7));
        continue;
      }

      final header = RegExp(r'^\s*(#{1,6})\s+(.*)$').firstMatch(line);
      if (header != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: RichText(
            text: TextSpan(
              children: _inline(
                header.group(2)!,
                style.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: style.fontSize! + 1),
              ),
            ),
          ),
        ));
        continue;
      }

      final bullet = RegExp(r'^\s*[\*\-]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 1, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: style),
              Expanded(
                child: RichText(text: TextSpan(children: _inline(bullet.group(1)!, style))),
              ),
            ],
          ),
        ));
        continue;
      }

      children.add(RichText(text: TextSpan(children: _inline(line, style))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<TextSpan> _inline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|`(.+?)`');
    int last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      final bold = m.group(1) ?? m.group(2);
      if (bold != null) {
        spans.add(TextSpan(
            text: bold, style: base.copyWith(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(
            text: m.group(3),
            style: base.copyWith(
                fontFamily: 'monospace',
                color: const Color(0xFF7CF5EE))));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }
}
