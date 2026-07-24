package works.endoftime.plurishaven;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterCallbackInformation;

public final class PlurisBackgroundWorker extends Worker {
    public static final String CONTROL_CHANNEL =
            "works.endoftime.plurishaven/background_tasks";
    public static final String WORKER_CHANNEL =
            "works.endoftime.plurishaven/background_tasks/worker";
    public static final String PREFERENCES = "pluris_haven_background_tasks";
    public static final String CALLBACK_HANDLE_KEY = "callback_handle";
    public static final String JOB_ID_KEY = "job_id";
    public static final String TASK_KEY = "task";
    private static final long TIMEOUT_MINUTES = 9L;

    private volatile FlutterEngine engine;

    public PlurisBackgroundWorker(
            @NonNull Context applicationContext,
            @NonNull WorkerParameters workerParameters
    ) {
        super(applicationContext, workerParameters);
    }

    @NonNull
    @Override
    public Result doWork() {
        Context context = getApplicationContext();
        long callbackHandle = context.getSharedPreferences(
                PREFERENCES,
                Context.MODE_PRIVATE
        ).getLong(CALLBACK_HANDLE_KEY, -1L);
        FlutterCallbackInformation callbackInfo =
                FlutterCallbackInformation.lookupCallbackInformation(callbackHandle);
        if (callbackInfo == null) return Result.failure();
        String task = getInputData().getString(TASK_KEY);
        if (task == null) return Result.failure();
        String jobId = getInputData().getString(JOB_ID_KEY);
        CountDownLatch completion = new CountDownLatch(1);
        AtomicReference<Result> outcome = new AtomicReference<>(Result.retry());
        Handler mainHandler = new Handler(Looper.getMainLooper());
        FlutterLoader loader = FlutterInjector.instance().flutterLoader();

        mainHandler.post(() -> {
            if (!loader.initialized()) loader.startInitialization(context);
            loader.ensureInitializationCompleteAsync(
                    context,
                    null,
                    mainHandler,
                    () -> startEngine(
                            context,
                            loader,
                            callbackInfo,
                            task,
                            jobId,
                            completion,
                            outcome
                    )
            );
        });

        boolean completed;
        try {
            completed = completion.await(TIMEOUT_MINUTES, TimeUnit.MINUTES);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            completed = false;
        }
        mainHandler.post(this::destroyEngine);
        return completed ? outcome.get() : Result.retry();
    }

    private void startEngine(
            Context context,
            FlutterLoader loader,
            FlutterCallbackInformation callbackInfo,
            String task,
            String jobId,
            CountDownLatch completion,
            AtomicReference<Result> outcome
    ) {
        if (isStopped()) {
            completion.countDown();
            return;
        }
        try {
            FlutterEngine flutterEngine = new FlutterEngine(context);
            engine = flutterEngine;
            MethodChannel channel = new MethodChannel(
                    flutterEngine.getDartExecutor().getBinaryMessenger(),
                    WORKER_CHANNEL
            );
            channel.setMethodCallHandler((call, readyResult) -> {
                if (!"backgroundReady".equals(call.method)) {
                    readyResult.notImplemented();
                    return;
                }
                readyResult.success(null);
                Map<String, Object> inputData = new HashMap<>();
                inputData.put("job_id", jobId);
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("task", task);
                arguments.put("inputData", inputData);
                channel.invokeMethod(
                        "runTask",
                        arguments,
                        new MethodChannel.Result() {
                            @Override
                            public void success(Object result) {
                                outcome.set(Boolean.TRUE.equals(result)
                                        ? Result.success()
                                        : Result.retry());
                                completion.countDown();
                            }

                            @Override
                            public void error(
                                    String code,
                                    String message,
                                    Object details
                            ) {
                                outcome.set(Result.retry());
                                completion.countDown();
                            }

                            @Override
                            public void notImplemented() {
                                outcome.set(Result.failure());
                                completion.countDown();
                            }
                        }
                );
            });
            flutterEngine.getDartExecutor().executeDartCallback(
                    new DartExecutor.DartCallback(
                            context.getAssets(),
                            loader.findAppBundlePath(),
                            callbackInfo
                    )
            );
        } catch (Exception error) {
            outcome.set(Result.retry());
            completion.countDown();
        }
    }

    private void destroyEngine() {
        FlutterEngine current = engine;
        engine = null;
        if (current != null) current.destroy();
    }

    @Override
    public void onStopped() {
        new Handler(Looper.getMainLooper()).post(this::destroyEngine);
        super.onStopped();
    }
}
