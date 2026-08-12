import 'dart:async';

import 'package:flutter/material.dart';

import 'generated/original_style.dart';
import 'src/media.dart';
import 'src/pages.dart';
import 'src/settings_pages.dart';
import 'src/store.dart';
import 'src/theme.dart';
import 'src/webdav.dart';
import 'src/widgets.dart';

const bool _visualReview =
    bool.fromEnvironment('VISUAL_REVIEW', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RainbowMediaStore.instance.initialize();
  final RainbowStore store = RainbowStore(
    _visualReview ? MemoryRainbowStorage() : SharedPreferencesRainbowStorage(),
    clock: _visualReview ? () => DateTime(2026, 8, 11, 12) : null,
  );
  if (_visualReview) {
    store.seedForTest();
  } else {
    await store.initialize();
  }
  runApp(RainbowCatsApp(store: store, visualReview: _visualReview));
  if (!_visualReview &&
      store.settings.autoSync &&
      store.settings.hasWebDav) {
    unawaited(_runStartupSync(store));
  }
}

Future<void> _runStartupSync(RainbowStore store) async {
  try {
    final RemoteOperationResult result = await WebDavClient().synchronize(store);
    store.recordSyncResult(ok: result.ok, message: result.message);
  } on Object catch (error) {
    store.recordSyncResult(ok: false, message: '启动同步失败：$error');
  }
}

class RainbowCatsApp extends StatelessWidget {
  const RainbowCatsApp({
    required this.store,
    this.visualReview = false,
    super.key,
  });

  final RainbowStore store;
  final bool visualReview;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: OriginalStyle.appTitle,
        debugShowCheckedModeBanner: false,
        theme: RainbowTheme.light,
        builder: (BuildContext context, Widget? child) => LiquidBackground(
          child: child ?? const SizedBox.shrink(),
        ),
        routes: <String, WidgetBuilder>{
          '/settings': (_) => SettingsPage(store: store),
          '/ledger': (_) => PointLedgerPage(store: store),
        },
        home: AnimatedBuilder(
          animation: store,
          builder: (BuildContext context, _) => visualReview
              ? VisualReviewCatalog(store: store)
              : RainbowShell(store: store),
        ),
      );
}
