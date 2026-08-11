from pathlib import Path

path = Path('app/lib/src/settings_pages.dart')
text = path.read_text(encoding='utf-8')
start = text.index('  Future<_MemberFormValue?> _memberDialog(Member? member) async {')
end = text.index('\n\nclass PointLedgerPage', start)
replacement = '''  Future<_MemberFormValue?> _memberDialog(
    BuildContext context, {
    required String title,
    required String name,
    required int credit,
  }) async {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController creditController =
        TextEditingController(text: credit.toString());
    final DialogRoute<_MemberFormValue> route = DialogRoute<_MemberFormValue>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('member-name'),
              controller: nameController,
              maxLength: 12,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey<String>('member-credit'),
              controller: creditController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(labelText: '积分'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                _MemberFormValue(
                  nameController.text,
                  int.tryParse(creditController.text) ?? 0,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final _MemberFormValue? result = await Navigator.of(context).push(route);
    await route.completed;
    nameController.dispose();
    creditController.dispose();
    return result;
  }

  void _showResult(BuildContext context, ActionResult result) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }
}'''
path.write_text(text[:start] + replacement + text[end:], encoding='utf-8')
