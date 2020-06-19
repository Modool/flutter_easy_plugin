#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterEasyPluginResult : NSObject

+ (instancetype)notImplemention;

+ (instancetype)empty;

+ (instancetype)return:(id)value;

+ (instancetype)error:(NSError *)error;

+ (instancetype)async:(void (^)(void (^done)(id value, NSError *_Nullable error)))block;

@end

@interface FlutterEasyPlugin : NSObject<FlutterPlugin>

@property (nonatomic, copy, class, readonly) NSString *channelName;

@property (nonatomic, strong, readonly) FlutterMethodChannel *methodChannel;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
