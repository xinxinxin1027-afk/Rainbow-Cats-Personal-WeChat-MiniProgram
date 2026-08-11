from pathlib import Path

p = Path('app/lib/src/pages.dart')
s = p.read_text(encoding='utf-8')
old = '''  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Text(label, style: const TextStyle(color: OriginalStyle.muted)),
            const Spacer(),
            trailing ??
                Text(
                  value ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
          ],
        ),
      );
}'''
new = '''  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: OriginalStyle.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ??
                    Text(
                      value ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
              ),
            ),
          ],
        ),
      );
}'''
if old not in s:
    raise SystemExit('detail row target not found')
p.write_text(s.replace(old, new, 1), encoding='utf-8')
