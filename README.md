# Flutter Easy Plugin

A plugin basic class for Flutter. To implement method of plugin class directly without `handleMethodCall` or `onMethodCall` .

![Flutter Test](https://github.com/Modool/flutter_easy_plugin/workflows/Flutter%20Test/badge.svg) [![pub package](https://img.shields.io/pub/v/flutter_easy_plugin.svg)](https://pub.dartlang.org/packages/flutter_easy_plugin) [![Build Status](https://app.bitrise.io/app/fa4f5d4bf452bcfb/status.svg?token=HorGpL_AOw2llYz39CjmdQ&branch=master)](https://app.bitrise.io/app/fa4f5d4bf452bcfb) [![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://github.com/tenhobi/effective_dart)

## Features

* Class `FlutterEasyPlugin` must be as parent class.
* Subclass implement plugin method directly without `handleMethodCall` or `onMethodCall`.
* Just like an native method implementation for Flutter channel call.
* Support result such as return-value, async-return-value and error for implemented method. 
* Try to see examples for detail or see method `getPlatformVersion`.  

## Usage

To use this plugin, add `flutter_easy_plugin` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_easy_plugin: 0.0.1
```

## API

### iOS

```objc

// iOS result
@interface FlutterEasyPluginResult : NSObject

+ (instancetype)notImplemention;

+ (instancetype)return:(id)value;

+ (instancetype)error:(NSError *)error;

+ (instancetype)async:(void (^)(void (^done)(id value, NSError *_Nullable error)))block;

@end

// iOS base class
@interface FlutterEasyPlugin : NSObject<FlutterPlugin>

@property (nonatomic, copy, class, readonly) NSString *channelName;

@property (nonatomic, strong, readonly) FlutterMethodChannel *methodChannel;

- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel NS_DESIGNATED_INITIALIZER;

@end

```

### Android

```java
// Android Result
public abstract class FlutterEasyPluginResult {
    public static FlutterEasyPluginResult success(Object object) {
        return new FlutterEasyPluginReturnResult(object);
    }

    public static FlutterEasyPluginResult error(Error error) {
        return new FlutterEasyPluginErrorResult(error);
    }

    public static FlutterEasyPluginResult notImplemented() {
        return new FlutterEasyPluginNotImplementedResult();
    }
    public static FlutterEasyPluginResult async(AsyncExcutor excutor) {
        return new FlutterEasyPluginAsyncResult(excutor);
    }
}

// Android base class
public class FlutterEasyPlugin implements MethodCallHandler {}
```


## Issues

Please file any issues, bugs or feature request as an issue on our [Github](https://github.com/modool/flutter_easy_plugin/issues) page.

## Want to contribute

If you would like to contribute to the plugin (e.g. by improving the documentation, solving a bug or adding a cool new feature), please carefully review our [contribution guide](CONTRIBUTING.md) and send us your [pull request](https://github.com/modool/flutter_easy_plugin/pulls).

## Author

This Flutter easy plugin for Flutter is developed by [modool](https://github.com/modool). You can contact us at <modool.go@gmail.com>
