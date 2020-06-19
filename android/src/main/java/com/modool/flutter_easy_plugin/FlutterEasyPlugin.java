package com.modool.flutter_easy_plugin;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;


public class FlutterEasyPlugin implements MethodCallHandler {
    /**
     * FlutterEasyPlugin
     */
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        final Object args = call.arguments;
        final List<Class> parameterTypes = new ArrayList();

        if (args != null) {
            if (args instanceof List) {
                for (Object arg : (List) args) {
                    parameterTypes.add(arg.getClass());
                }
            } else {
                parameterTypes.add(args.getClass());
            }
        }

        Method method = null;
        if (method == null) {
            try {
                method = getClass().getDeclaredMethod(call.method, parameterTypes.toArray(new Class[0]));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (method == null) {
            result.notImplemented();
            return;
        }
        try {
            method.setAccessible(true);

            Object object;
            if (args instanceof List) {
                object = method.invoke(this, (Object[]) ((List) args).toArray());
            } else if (args != null) {
                object = method.invoke(this, args);
            } else {
                object = method.invoke(this);
            }
            if (object instanceof FlutterEasyPluginResult) {
                ((FlutterEasyPluginResult) object).excute(result);
            } else {
                result.success(object);
            }
        } catch (RuntimeException e) {
            e.printStackTrace();

            result.error(e.getMessage(), e.getStackTrace().toString(), null);
        } catch (IllegalAccessException e) {
            e.printStackTrace();

            result.error(e.getMessage(), e.getStackTrace().toString(), null);
        } catch (InvocationTargetException e) {
            e.printStackTrace();

            result.error(e.getMessage(), e.getStackTrace().toString(), null);
        }
    }

    public String getPlatformVersion() {
        return "Android " + android.os.Build.VERSION.RELEASE;
    }


    public static void registerWith(final PluginRegistry.Registrar registrar) {
        if (registrar.activity() == null) {
            // If a background flutter view tries to register the plugin, there will be no activity from the registrar,
            // we stop the registering process immediately because the ImagePicker requires an activity.
            return;
        }
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.modool.flutter/flutter_easy_plugin");

        final FlutterEasyPlugin instance = new FlutterEasyPlugin();
        channel.setMethodCallHandler(instance);
    }
}
