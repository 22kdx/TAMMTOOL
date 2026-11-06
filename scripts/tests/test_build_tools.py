"""Offline smoke tests: python3 -m unittest discover -s scripts/tests -v."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class BuildToolsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        shutil.copytree(ROOT / 'scripts', self.root / 'scripts')
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f'{self.bin}:/usr/bin:/bin',
                        ANDROID_HOME='', ANDROID_SDK_ROOT='', ANDROID_SERIAL='')
        self.apk = self.root / 'test.apk'
        self.apk.write_bytes(b'fake apk')

    def tool(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/bash\nset -eu\n' + body)
        path.chmod(0o755)

    def run_script(self, script, *args):
        return subprocess.run(['bash', str(self.root / 'scripts' / script), *map(str, args)],
                              env=self.env, capture_output=True, text=True)

    def test_no_devices(self):
        self.tool('adb', 'if [[ $1 == devices ]]; then echo "List of devices attached"; fi\n')
        p = self.run_script('apk-test.sh', 'install', self.apk)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('No authorized devices', p.stderr)

    def test_multiple_devices(self):
        self.tool('adb', 'if [[ $1 == devices ]]; then printf "List of devices attached\\na\\tdevice\\nb\\tdevice\\n"; fi\n')
        p = self.run_script('apk-test.sh', 'install', self.apk)
        self.assertIn('Multiple devices', p.stderr)
        self.assertEqual(self.run_script('apk-test.sh', 'install', self.apk, 'b').returncode, 0)

    def test_unauthorized_device(self):
        self.tool('adb', 'if [[ $1 == devices ]]; then printf "a\\tunauthorized\\n"; fi\n')
        p = self.run_script('apk-test.sh', 'install', self.apk, 'a')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('unauthorized', p.stderr)

    def test_info(self):
        self.tool('aapt', 'echo "package: name=example.test versionCode=1 versionName=1.0"\n')
        p = self.run_script('apk-test.sh', 'info', self.apk)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('example.test', p.stdout)
        self.assertIn('8 bytes', p.stdout)

    def projects(self, fail=False):
        for app in ('marketer', 'orders-delivery'):
            project = self.root / 'apps' / app
            project.mkdir(parents=True)
            (project / 'settings.gradle.kts').touch()
            (project / 'gradlew').write_text('exit 7\n' if fail else
                'mkdir -p app/build/outputs/apk/debug\nprintf fake > app/build/outputs/apk/debug/app-debug.apk\n')

    def test_both_apps(self):
        self.projects()
        p = self.run_script('build-apk.sh')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout.count('Size:'), 2)

    def test_legacy_argument_order_and_log(self):
        self.projects()
        p = self.run_script('build-apk.sh', 'debug', 'marketer')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertTrue((self.root / '.build-logs/marketer-debug.log').is_file())

    def test_smoke_test_uses_apk_package_without_uninstall(self):
        self.tool('aapt', "echo \"package: name='com.example.test' versionCode='1' versionName='1.0'\"\n")
        log = self.root / 'adb.log'
        self.env['ADB_TEST_LOG'] = str(log)
        self.tool('adb', 'echo "$*" >> "$ADB_TEST_LOG"\nif [[ $1 == devices ]]; then printf "a\\tdevice\\n"; fi\n')
        p = self.run_script('apk-test.sh', 'test', self.apk)
        self.assertEqual(p.returncode, 0, p.stderr)
        calls = log.read_text()
        self.assertIn('-s a install -r', calls)
        self.assertIn('monkey -p com.example.test', calls)
        self.assertNotIn('uninstall', calls)

    def test_signed_release_and_verify(self):
        self.projects()
        project = self.root / 'apps/marketer'
        (project / 'gradlew').write_text(
            'mkdir -p app/build/outputs/apk/release\nprintf fake > app/build/outputs/apk/release/app-release-unsigned.apk\n')
        key = self.root / 'signing key.jks'
        key.touch()
        self.env.update(APK_KEYSTORE=str(key), APK_KEY_ALIAS='test',
                        APK_STORE_PASSWORD='private-store', APK_KEY_PASSWORD='private-key')
        self.tool('zipalign', 'cp "$4" "$5"\n')
        self.tool('apksigner',
                  'if [[ $1 == sign ]]; then\n'
                  'while [[ $1 != --out ]]; do shift; done\n'
                  'cp "$3" "$2"\n'
                  'elif [[ $1 == verify ]]; then test -f "$2"; fi\n')
        p = self.run_script('build-apk.sh', 'marketer', 'release')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertTrue((project / 'app/build/outputs/apk/release/app-release-unsigned-signed.apk').is_file())
        self.assertNotIn('private-store', p.stdout + p.stderr)
        self.assertNotIn('private-key', p.stdout + p.stderr)

    def test_success_without_apk_fails(self):
        self.projects()
        (self.root / 'apps/marketer/gradlew').write_text('exit 0\n')
        p = self.run_script('build-apk.sh', 'marketer')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('no APK found', p.stderr)

    def test_sdk_setup_unknown_option(self):
        p = self.run_script('android-sdk-setup.sh', '--invalid')
        self.assertEqual(p.returncode, 2)

    def test_diagnose_preserves_failure_and_log(self):
        self.projects(fail=True)
        p = self.run_script('diagnose-apk.sh', 'marketer')
        self.assertEqual(p.returncode, 7, p.stderr)
        report = (self.root / '.build-logs/diagnose-marketer.log').read_text()
        self.assertIn('BUILD_EXIT=7', report)
        self.assertEqual((self.root / '.build-logs/diagnose-marketer.exit-code').read_text().strip(), '7')

    def test_diagnose_success(self):
        self.projects()
        p = self.run_script('diagnose-apk.sh', 'marketer')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('BUILD_EXIT=0', p.stdout)

    def test_sdk_preflight_complete_without_adb(self):
        sdk = self.root / 'sdk'
        platform = sdk / 'platforms/android-35'
        platform.mkdir(parents=True)
        (platform / 'android.jar').write_bytes(b'jar')
        tools = sdk / 'build-tools/35.0.0'
        tools.mkdir(parents=True)
        for name in ('aapt2', 'zipalign', 'apksigner'):
            tool = tools / name
            tool.write_text('#!/bin/sh\nexit 0\n')
            tool.chmod(0o755)
        self.env.update(ANDROID_HOME=str(sdk), ANDROID_SDK_ROOT=str(sdk),
                        ANDROID_API_LEVEL='35', ANDROID_BUILD_TOOLS_VERSION='35.0.0')
        p = self.run_script('check-sdk.sh')
        self.assertEqual(p.returncode, 0, p.stderr)
        (tools / 'aapt2').unlink()
        p = self.run_script('check-sdk.sh')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('aapt2', p.stderr)

    def test_sdk_preflight_rejects_wrong_platform(self):
        sdk = self.root / 'sdk'
        sdk.mkdir()
        self.env.update(ANDROID_HOME=str(sdk), ANDROID_API_LEVEL='35')
        p = self.run_script('check-sdk.sh')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('android-35', p.stderr)

    def test_gradle_failure(self):
        self.projects(fail=True)
        p = self.run_script('build-apk.sh')
        self.assertEqual(p.returncode, 7)
        self.assertIn('build failed', p.stderr)

    def test_missing_project(self):
        p = self.run_script('build-apk.sh')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('project missing', p.stderr)

    def test_release_requires_secrets(self):
        for key in ('APK_KEYSTORE', 'APK_KEY_ALIAS', 'APK_STORE_PASSWORD', 'APK_KEY_PASSWORD'):
            self.env.pop(key, None)
        p = self.run_script('build-apk.sh', 'all', 'release')
        self.assertNotEqual(p.returncode, 0)
        self.assertIn('required for signed release', p.stderr)


if __name__ == '__main__':
    unittest.main()
