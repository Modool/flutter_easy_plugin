import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const channel = MethodChannel('com.modool.flutter/flutter_easy_plugin');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String platformVersion;

  @override
  void initState() {
    channel.invokeMethod('getPlatformVersion').then((platformVersion) {
      setState(() {
        this.platformVersion = platformVersion;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Text('getPlatformVersion: $platformVersion'),
          ],
        ),
      ),
    );
  }
}
