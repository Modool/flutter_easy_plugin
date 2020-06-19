#import <objc/runtime.h>

#import "FlutterEasyPlugin.h"

FlutterError *_FlutterErrorWithError(NSError *error) {
    return [FlutterError errorWithCode:@(error.code).stringValue message:error.localizedDescription details:nil];
};

@interface FlutterEasyPluginResult ()

- (void)_excuteWithResult:(FlutterResult)result;

@end

@interface FlutterEasyPluginReturnResult : FlutterEasyPluginResult {
    id _value;
}

@end

@implementation FlutterEasyPluginReturnResult

+ (instancetype)return:(id)value {
    FlutterEasyPluginReturnResult *result = [[self alloc] init];
    result->_value = value;
    return result;
}

+ (instancetype)empty {
    return [[self alloc] init];
}

- (void)_excuteWithResult:(FlutterResult)result {
    result(_value);
}

@end

@interface FlutterEasyPluginAsyncResult : FlutterEasyPluginResult {
    void (^_block)(void (^done)(id value, NSError *error));
}

@end

@implementation FlutterEasyPluginAsyncResult

+ (instancetype)async:(void (^)(void (^done)(id value, NSError *error)))block {
    NSParameterAssert(block);

    FlutterEasyPluginAsyncResult *result = [[self alloc] init];
    result->_block = [block copy];

    return result;
}

- (void)_excuteWithResult:(FlutterResult)result {
    _block(^(id value, NSError *error){
        if (error) result(_FlutterErrorWithError(error));
        else result(value);
    });
}

@end

@implementation FlutterEasyPluginResult

+ (instancetype)notImplemention {
    return [FlutterEasyPluginReturnResult return:FlutterMethodNotImplemented];
}

+ (instancetype)empty {
    return [FlutterEasyPluginReturnResult empty];
}

+ (instancetype)return:(id)value {
    return [FlutterEasyPluginReturnResult return:value];
}

+ (instancetype)error:(NSError *)error {
    return [FlutterEasyPluginReturnResult return:_FlutterErrorWithError(error)];
}

+ (instancetype)async:(void (^)(void (^done)(id value, NSError *error)))block {
    return [FlutterEasyPluginAsyncResult async:block];
}

- (void)_excuteWithResult:(FlutterResult)result {}

@end

@implementation FlutterEasyPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:self.channelName
                                     binaryMessenger:[registrar messenger]];
    FlutterEasyPlugin* instance = [[self alloc] initWithMethodChannel:channel];

    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel {
    if (self = [super init]) {
        _methodChannel = methodChannel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSError *error = nil;
    id returnValue = [self _invokeWithTarget:self methodName:call.method arguments:call.arguments error:&error];

    if (!error && [returnValue isKindOfClass:FlutterEasyPluginResult.class]) {
        [returnValue _excuteWithResult:result];
    } else if (error) {
        result(_FlutterErrorWithError(error));
    } else {
        result(returnValue);
    }
}

+ (NSString *)channelName {
    return @"com.modool.flutter/flutter_easy_plugin";
}

- (NSString *)getPlatformVersion {
    return [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]];
}

#pragma mark - private

- (id)_invokeWithTarget:(id)target methodName:(NSString *)methodName arguments:(NSArray *)arguments error:(NSError **)error {
    NSInvocation *invocation = [self _invocationWithTarget:target methodName:methodName arguments:arguments];
    if (!invocation) {
        if (error) *error = [NSError errorWithDomain:@"com.flutter.easy.plugin" code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Can't find method %@", methodName]}];
        return nil;
    }

    [invocation retainArguments];
    [invocation invokeWithTarget:target];

    return [self _returnObjectOfInvocation:invocation];
}

- (NSInvocation *)_invocationWithTarget:(id)target methodName:(NSString *)methodName arguments:(NSArray *)arguments {
    arguments = [arguments isKindOfClass:NSArray.class] ? arguments : @[arguments ?:NSNull.null];

    Class class = [target class];
    BOOL isClassMethod = class == target;

    Method method = [self _methodInClass:[target class] isClassMethod:isClassMethod forName:methodName];
    if (!method) return nil;

    return [self _invocationFromMethod:method arguments:arguments];
}

- (NSInvocation *)_invocationFromMethod:(Method)method arguments:(NSArray *)arguments {
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = method_getName(method);

    NSUInteger actualArgumentsCount = arguments.count;
    NSUInteger requiredArgumentsCount = signature.numberOfArguments;

    for (int i = 2; i < requiredArgumentsCount; i++) {
        if ((i - 2) >= actualArgumentsCount) break;

        id argument = arguments[i - 2];
        argument = argument == NSNull.null ? nil : argument;

        [self _setInvocationArgument:invocation index:i value:argument];
    }
    return invocation;
}

- (Method)_methodInClass:(Class)class isClassMethod:(BOOL)isClassMethod forName:(NSString *)name {
    SEL selector = NSSelectorFromString(name);
    Method method = NULL;
    if (isClassMethod) {
        method = class_getClassMethod(class, selector);
    } else {
        method = class_getInstanceMethod(class, selector);
    }

    if (method != NULL) return method;

    Class superClass = class_getSuperclass(class);
    if (superClass) return [self _methodInClass:superClass isClassMethod:isClassMethod forName:name];

    return NULL;
}


#define INVOCATION_SET_RETURN_NUMBER_VALUE(ENCODING, TYPE, DEFAULT)   \
INVOCATION_SET_RETURN(ENCODING, TYPE, DEFAULT, @(value))

#define INVOCATION_SET_RETURN_VALUE(ENCODING, TYPE, DEFAULT, VALUE_METHOD)   \
INVOCATION_SET_RETURN(ENCODING, TYPE, DEFAULT, [NSValue VALUE_METHOD:value])

#define INVOCATION_SET_RETURN_OBJECT(ENCODING, TYPE, DEFAULT)           \
INVOCATION_SET_RETURN(ENCODING, TYPE, DEFAULT, value)

#define INVOCATION_SET_RETURN(ENCODING, TYPE, DEFAULT, RESULT)          \
(strcmp(ENCODING, @encode(TYPE)) == 0) {                             \
    TYPE value = DEFAULT;                                               \
    [invocation getReturnValue:&value];                                 \
    return RESULT;                                                     \
}

- (id)_returnObjectOfInvocation:(NSInvocation *)invocation {
    const char *type = invocation.methodSignature.methodReturnType;

    if (strcmp(type, @encode(void)) == 0) return nil;
    else if (strcmp(type, @encode(id)) == 0) {
        void *value = NULL;
        if (invocation.methodSignature.methodReturnLength) {
            [invocation getReturnValue:&value];
        }
        return (__bridge id)value;
    }
    else if INVOCATION_SET_RETURN_VALUE(type, CGPoint, CGPointZero, valueWithCGPoint)
    else if INVOCATION_SET_RETURN_VALUE(type, CGSize, CGSizeZero, valueWithCGSize)
    else if INVOCATION_SET_RETURN_VALUE(type, CGRect, CGRectZero, valueWithCGRect)
    else if INVOCATION_SET_RETURN_VALUE(type, CGVector, CGVectorMake(0, 0), valueWithCGVector)
    else if INVOCATION_SET_RETURN_VALUE(type, CGAffineTransform, CGAffineTransformIdentity, valueWithCGAffineTransform)
    else if INVOCATION_SET_RETURN_VALUE(type, UIOffset, UIOffsetZero, valueWithUIOffset)
    else if INVOCATION_SET_RETURN_VALUE(type, UIEdgeInsets, UIEdgeInsetsZero, valueWithUIEdgeInsets)
    else if INVOCATION_SET_RETURN_VALUE(type, NSRange, NSMakeRange(0, 0), valueWithRange)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, double, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, float, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, bool, false)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, int, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, char, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, short, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, long, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, unsigned int, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, unsigned char, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, unsigned short, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, unsigned long, 0)
    else if INVOCATION_SET_RETURN_NUMBER_VALUE(type, unsigned long long, 0)
    else if (@available(iOS 11, *)) {
        if INVOCATION_SET_RETURN_VALUE(type, NSDirectionalEdgeInsets, NSDirectionalEdgeInsetsZero, valueWithDirectionalEdgeInsets)
    }
    return nil;
}

#define SET_INVOCATION_ARGUMENT(ENCODING, TYPE, METHOD, INDEX)      \
(strcmp(ENCODING, @encode(TYPE)) == 0) {                            \
    TYPE result = [number METHOD];                                  \
    [invocation setArgument:&result atIndex:INDEX];                 \
    return;                                                         \
}

- (void)_setInvocationArgument:(NSInvocation *)invocation index:(int)index value:(id)value {
    NSMethodSignature *signature = [invocation methodSignature];
    const char *type = [signature getArgumentTypeAtIndex:index];

    if (strcmp(type, @encode(id)) == 0) {
        [invocation setArgument:&value atIndex:index];
        return;
    }
    NSNumber *number = value;
    if SET_INVOCATION_ARGUMENT(type, CGPoint, CGPointValue, index)
    else if SET_INVOCATION_ARGUMENT(type, CGSize, CGSizeValue, index)
    else if SET_INVOCATION_ARGUMENT(type, CGRect, CGRectValue, index)
    else if SET_INVOCATION_ARGUMENT(type, CGVector, CGVectorValue, index)
    else if SET_INVOCATION_ARGUMENT(type, CGAffineTransform, CGAffineTransformValue, index)
    else if SET_INVOCATION_ARGUMENT(type, UIOffset, UIOffsetValue, index)
    else if SET_INVOCATION_ARGUMENT(type, UIEdgeInsets, UIEdgeInsetsValue, index)
    else if SET_INVOCATION_ARGUMENT(type, NSRange, rangeValue, index)
    else if SET_INVOCATION_ARGUMENT(type, double, doubleValue, index)
    else if SET_INVOCATION_ARGUMENT(type, float, floatValue, index)
    else if SET_INVOCATION_ARGUMENT(type, bool, boolValue, index)
    else if SET_INVOCATION_ARGUMENT(type, int, intValue, index)
    else if SET_INVOCATION_ARGUMENT(type, char, charValue, index)
    else if SET_INVOCATION_ARGUMENT(type, short, shortValue, index)
    else if SET_INVOCATION_ARGUMENT(type, long, longValue, index)
    else if SET_INVOCATION_ARGUMENT(type, unsigned int, unsignedIntValue, index)
    else if SET_INVOCATION_ARGUMENT(type, unsigned char, unsignedCharValue, index)
    else if SET_INVOCATION_ARGUMENT(type, unsigned short, unsignedShortValue, index)
    else if SET_INVOCATION_ARGUMENT(type, unsigned long, unsignedLongValue, index)
    else if SET_INVOCATION_ARGUMENT(type, unsigned long long, unsignedLongLongValue, index)
    else if (@available(iOS 11, *)) {
        if ([value isKindOfClass:[NSValue class]]) {
            if SET_INVOCATION_ARGUMENT(type, NSDirectionalEdgeInsets, directionalEdgeInsetsValue, index)
        }
    }
}

@end
