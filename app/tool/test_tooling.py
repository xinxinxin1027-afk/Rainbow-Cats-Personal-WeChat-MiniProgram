#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent


class ToolingTest(unittest.TestCase):
    def _copy_tool(self, repo: Path, name: str) -> Path:
        target = repo / 'app/tool' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(HERE / name, target)
        return target

    def test_original_asset_and_style_generation(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            app = repo / 'app'
            (app / 'lib/generated').mkdir(parents=True)
            self._copy_tool(repo, 'import_original_assets.py')
            self._copy_tool(repo, 'extract_original_style.py')

            mini = repo / 'miniprogram'
            (mini / 'pages/MainPage').mkdir(parents=True)
            (mini / 'pages/Mission').mkdir(parents=True)
            (mini / 'images/TabBar').mkdir(parents=True)
            (mini / 'node_modules/vendor').mkdir(parents=True)
            app_json = {
                'window': {
                    'backgroundColor': '#F6F6F6',
                    'navigationBarBackgroundColor': '#FF99AA',
                    'navigationBarTitleText': '卡比们的任务',
                },
                'tabBar': {
                    'color': '#1A1A1A',
                    'selectedColor': '#FF99AA',
                    'list': [
                        {
                            'pagePath': 'pages/MainPage/index',
                            'iconPath': 'images/TabBar/home-grey.png',
                            'selectedIconPath': 'images/TabBar/home-pink.png',
                            'text': '首页',
                        }
                    ],
                },
            }
            (mini / 'app.json').write_text(
                json.dumps(app_json, ensure_ascii=False), encoding='utf-8'
            )
            (mini / 'pages/MainPage/index.json').write_text(
                json.dumps({'navigationBarTitleText': '首页'}, ensure_ascii=False),
                encoding='utf-8',
            )
            (mini / 'pages/MainPage/index.wxml').write_text(
                '<image src="../../images/banner.png"/>', encoding='utf-8'
            )
            (mini / 'pages/MainPage/index.wxss').write_text(
                '.card{border-radius:28rpx;background:#F6F6F6;color:#333333}',
                encoding='utf-8',
            )
            (mini / 'images/banner.png').write_bytes(b'first-party-banner')
            (mini / 'images/TabBar/home-grey.png').write_bytes(b'grey')
            (mini / 'images/TabBar/home-pink.png').write_bytes(b'pink')
            (mini / 'node_modules/vendor/unused.png').write_bytes(b'unused')

            subprocess.run(
                ['python3', str(repo / 'app/tool/import_original_assets.py')],
                cwd=repo,
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(
                ['python3', str(repo / 'app/tool/extract_original_style.py')],
                cwd=repo,
                check=True,
                capture_output=True,
                text=True,
            )

            copied = list((app / 'assets/original').iterdir())
            self.assertEqual(len(copied), 3)
            generated_assets = (app / 'lib/generated/original_assets.dart').read_text(
                encoding='utf-8'
            )
            self.assertIn('banner.png', generated_assets)
            self.assertIn('home-grey.png', generated_assets)
            self.assertNotIn('unused.png', generated_assets)
            generated_style = (app / 'lib/generated/original_style.dart').read_text(
                encoding='utf-8'
            )
            self.assertIn('0xFFFF99AA', generated_style)
            self.assertIn('0xFFF6F6F6', generated_style)
            self.assertIn('cardRadius = 14.0', generated_style)

    def test_android_patch(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            app = repo / 'app'
            self._copy_tool(repo, 'patch_android.py')
            manifest = app / 'android/app/src/main/AndroidManifest.xml'
            manifest.parent.mkdir(parents=True)
            manifest.write_text(
                '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <application android:label="rainbow_cats" />\n'
                '</manifest>\n'''.replace("'\n                '", ''),
                encoding='utf-8',
            )
            gradle = app / 'android/app/build.gradle.kts'
            gradle.parent.mkdir(parents=True, exist_ok=True)
            gradle.write_text('plugins { id("com.android.application") }\n', encoding='utf-8')

            subprocess.run(
                ['python3', str(repo / 'app/tool/patch_android.py')],
                cwd=repo,
                check=True,
                capture_output=True,
                text=True,
            )

            patched = manifest.read_text(encoding='utf-8')
            self.assertIn('android.permission.INTERNET', patched)
            self.assertIn('android:label="Rainbow Cats"', patched)
            self.assertIn('android:usesCleartextTraffic="true"', patched)
            self.assertTrue(
                (app / 'android/app/src/main/res/drawable/launch_background.xml').exists()
            )
            self.assertTrue(
                (app / 'android/app/src/main/res/values-v31/styles.xml').exists()
            )
            self.assertIn(
                'RAINBOW_OPTIONAL_SIGNING', gradle.read_text(encoding='utf-8')
            )

    def test_committed_android_gradle_versions(self) -> None:
        app = HERE.parent
        settings = (app / 'android/settings.gradle.kts').read_text(encoding='utf-8')
        wrapper = (
            app / 'android/gradle/wrapper/gradle-wrapper.properties'
        ).read_text(encoding='utf-8')
        manifest = (
            app / 'android/app/src/main/AndroidManifest.xml'
        ).read_text(encoding='utf-8')
        self.assertIn('version "9.0.1"', settings)
        self.assertIn('version "2.3.20"', settings)
        self.assertIn('gradle-9.1.0-all.zip', wrapper)
        self.assertIn('android.permission.INTERNET', manifest)
        self.assertIn('android:usesCleartextTraffic="true"', manifest)


if __name__ == '__main__':
    unittest.main(verbosity=2)
