import 'package:flutter/services.dart';

class EasyMethodChannel extends MethodChannel {
  const EasyMethodChannel(String name) : super(name);

  Future<String> get platformVersion =>
      invokeMethod<String>('getPlatformVersion');
}
