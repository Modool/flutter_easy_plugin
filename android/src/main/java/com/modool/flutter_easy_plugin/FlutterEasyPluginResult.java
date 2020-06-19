package com.modool.flutter_easy_plugin;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;


public abstract class FlutterEasyPluginResult {
    public static FlutterEasyPluginResult empty() {
        return new FlutterEasyPluginReturnResult(null);
    }

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

    protected abstract void excute(MethodChannel.Result result);

    private static class FlutterEasyPluginNotImplementedResult extends FlutterEasyPluginResult {
        protected void excute(MethodChannel.Result result) {
            result.notImplemented();
        }
    }

    private static class FlutterEasyPluginReturnResult extends FlutterEasyPluginResult {
        FlutterEasyPluginReturnResult(Object returnValue) {
            this.returnValue = returnValue;
        }

        private Object returnValue;

        protected void excute(MethodChannel.Result result) {
            result.success(returnValue);
        }
    }

    private static class FlutterEasyPluginErrorResult extends FlutterEasyPluginResult {
        FlutterEasyPluginErrorResult(Error error) {
            this.error = error;
        }

        private Error error;

        protected void excute(MethodChannel.Result result) {
            result.error(error.getMessage(), error.getStackTrace().toString(), null);
        }
    }

    private static class FlutterEasyPluginAsyncResult extends FlutterEasyPluginResult {
        FlutterEasyPluginAsyncResult(AsyncExcutor excutor) {
            this.excutor = excutor;
        }

        private AsyncExcutor excutor;

        protected void excute(MethodChannel.Result result) {
            Completion completion = new Completion(result);

            excutor.excute(completion);
        }
    }

    class Completion {
        protected Completion(MethodChannel.Result result) {
            this.result = result;
        }

        private Result result;

        public void error(Error error) {
            result.error(error.getMessage(), error.getStackTrace().toString(), error);
        }

        public void success(Object value) {
            result.success(value);
        }
    }

    abstract class AsyncExcutor {
        abstract void excute(Completion completion);
    }
}
