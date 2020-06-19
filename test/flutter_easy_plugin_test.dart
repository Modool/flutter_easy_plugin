import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_easy_plugin/flutter_easy_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const channel = EasyMethodChannel('com.modool.flutter/flutter_easy_plugin');

  channel.setMockMethodCallHandler((call) async {
    if (call.method == 'getPlatformVersion') return 'success';

    return null;
  });

  test('get platform version', () async {
    final version = await channel.platformVersion;
    expect(version, 'success');
  });
}
