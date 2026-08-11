package works.endoftime.plurishaven;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.work.BackoffPolicy;
import androidx.work.Constraints;
import androidx.work.Data;
import androidx.work.ExistingWorkPolicy;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public final class MainActivity extends FlutterFragmentActivity {
    private static final String FILE_DIALOG_CHANNEL =
            "works.endoftime.plurishaven/file_dialog";

    private MethodChannel.Result pendingPickResult;
    private long pendingPickMaximumBytes = 32L * 1024L * 1024L;
    private MethodChannel.Result pendingSaveResult;
    private String pendingSaveSource;

    private final ActivityResultLauncher<Intent> pickLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    activityResult -> {
                        MethodChannel.Result result = pendingPickResult;
                        if (result == null) return;
                        pendingPickResult = null;
                        if (activityResult.getResultCode() != Activity.RESULT_OK) {
                            result.success(null);
                            return;
                        }
                        try {
                            List<Map<String, Object>> files = new ArrayList<>();
                            for (Uri uri : selectedUris(activityResult.getData())) {
                                files.add(copySelectionToCache(uri, pendingPickMaximumBytes));
                            }
                            result.success(files);
                        } catch (Exception error) {
                            result.error("pick_failed", error.getMessage(), null);
                        }
                    });

    private final ActivityResultLauncher<Intent> saveLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    activityResult -> {
                        MethodChannel.Result result = pendingSaveResult;
                        String sourcePath = pendingSaveSource;
                        if (result == null) return;
                        pendingSaveResult = null;
                        pendingSaveSource = null;
                        if (activityResult.getResultCode() != Activity.RESULT_OK
                                || sourcePath == null) {
                            result.success(false);
                            return;
                        }
                        Intent data = activityResult.getData();
                        Uri destination = data == null ? null : data.getData();
                        if (destination == null) {
                            result.success(false);
                            return;
                        }
                        try (InputStream input = new FileInputStream(sourcePath);
                             OutputStream output = getContentResolver()
                                     .openOutputStream(destination, "w")) {
                            if (output == null) {
                                throw new IllegalStateException(
                                        "Could not open the selected destination.");
                            }
                            input.transferTo(output);
                            result.success(true);
                        } catch (Exception error) {
                            result.error("save_failed", error.getMessage(), null);
                        }
                    });

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // A killed process cannot run Dart's per-file cleanup. Clear any
        // plaintext import staging left by an interrupted previous session.
        purgePickedFiles();
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                FILE_DIALOG_CHANNEL
        ).setMethodCallHandler(this::handleFileDialogCall);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                PlurisBackgroundWorker.CONTROL_CHANNEL
        ).setMethodCallHandler(this::handleBackgroundTaskCall);
    }

    private void handleBackgroundTaskCall(
            MethodCall call,
            MethodChannel.Result result
    ) {
        switch (call.method) {
            case "initialize":
                Number callbackHandle = call.argument("callbackHandle");
                if (callbackHandle == null) {
                    result.error(
                            "invalid_callback",
                            "Missing background callback handle.",
                            null
                    );
                    return;
                }
                getSharedPreferences(
                        PlurisBackgroundWorker.PREFERENCES,
                        MODE_PRIVATE
                ).edit().putLong(
                        PlurisBackgroundWorker.CALLBACK_HANDLE_KEY,
                        callbackHandle.longValue()
                ).apply();
                result.success(null);
                break;
            case "scheduleImport":
                String jobId = call.argument("job_id");
                String task = call.argument("task");
                if (isBlank(jobId) || isBlank(task)) {
                    result.error(
                            "invalid_task",
                            "Missing background task data.",
                            null
                    );
                    return;
                }
                Constraints constraints = new Constraints.Builder()
                        .setRequiresStorageNotLow(true)
                        .build();
                Data input = new Data.Builder()
                        .putString(PlurisBackgroundWorker.JOB_ID_KEY, jobId)
                        .putString(PlurisBackgroundWorker.TASK_KEY, task)
                        .build();
                OneTimeWorkRequest request =
                        new OneTimeWorkRequest.Builder(PlurisBackgroundWorker.class)
                                .setInputData(input)
                                .setConstraints(constraints)
                                .setBackoffCriteria(
                                        BackoffPolicy.EXPONENTIAL,
                                        1,
                                        TimeUnit.MINUTES
                                )
                                .addTag("imports")
                                .build();
                WorkManager.getInstance(getApplicationContext()).enqueueUniqueWork(
                        "import-" + jobId,
                        ExistingWorkPolicy.REPLACE,
                        request
                );
                result.success(null);
                break;
            default:
                result.notImplemented();
        }
    }

    private void handleFileDialogCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "pickFiles":
                openFileDialog(call, result);
                break;
            case "saveFile":
                openSaveDialog(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void openFileDialog(MethodCall call, MethodChannel.Result result) {
        if (pendingPickResult != null) {
            result.error("picker_busy", "A file picker is already open.", null);
            return;
        }
        purgePickedFiles();
        String type = call.argument("type");
        List<String> extensions = call.argument("allowedExtensions");
        boolean allowMultiple = Boolean.TRUE.equals(call.argument("allowMultiple"));
        Number maximumBytes = call.argument("maximumBytes");
        pendingPickMaximumBytes = maximumBytes == null
                ? 32L * 1024L * 1024L
                : maximumBytes.longValue();
        if (pendingPickMaximumBytes < 1) {
            result.error("invalid_limit", "File size limit must be positive.", null);
            return;
        }
        Set<String> mimeTypeSet = new LinkedHashSet<>();
        if ("image".equals(type)) {
            mimeTypeSet.add("image/*");
        } else if (extensions != null) {
            for (String extension : extensions) {
                mimeTypeSet.add(mimeTypeForExtension(extension));
            }
        }
        String[] mimeTypes = mimeTypeSet.toArray(new String[0]);
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mimeTypes.length == 1 ? mimeTypes[0] : "*/*");
        if (mimeTypes.length > 0) {
            intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
        }
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple);
        pendingPickResult = result;
        pickLauncher.launch(intent);
    }

    private void openSaveDialog(MethodCall call, MethodChannel.Result result) {
        if (pendingSaveResult != null) {
            result.error("picker_busy", "A save dialog is already open.", null);
            return;
        }
        String sourcePath = call.argument("sourcePath");
        String fileName = call.argument("fileName");
        if (isBlank(sourcePath) || isBlank(fileName)) {
            result.error(
                    "invalid_save",
                    "Missing export source or filename.",
                    null
            );
            return;
        }
        String mimeType = call.argument("mimeType");
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mimeType == null ? "application/octet-stream" : mimeType);
        intent.putExtra(Intent.EXTRA_TITLE, fileName);
        pendingSaveResult = result;
        pendingSaveSource = sourcePath;
        saveLauncher.launch(intent);
    }

    private List<Uri> selectedUris(Intent intent) {
        List<Uri> uris = new ArrayList<>();
        if (intent == null) return uris;
        Uri data = intent.getData();
        if (data != null) uris.add(data);
        ClipData clipData = intent.getClipData();
        if (clipData == null) return uris;
        for (int index = 0; index < clipData.getItemCount(); index++) {
            Uri uri = clipData.getItemAt(index).getUri();
            if (uri != null && !uris.contains(uri)) uris.add(uri);
        }
        return uris;
    }

    private Map<String, Object> copySelectionToCache(Uri uri, long maximumBytes) throws Exception {
        String displayName = queryDisplayName(uri);
        if (displayName == null) displayName = "selected-file";
        Long declaredSize = queryFileSize(uri);
        if (declaredSize != null && declaredSize > maximumBytes) {
            throw new IllegalArgumentException("Selected file exceeds the size limit.");
        }
        String safeName = displayName.replaceAll("[^A-Za-z0-9._ -]", "_");
        File directory = new File(getCacheDir(), "picked-files");
        if (!directory.mkdirs() && !directory.isDirectory()) {
            throw new IllegalStateException("Could not create the file cache.");
        }
        File output = File.createTempFile("picked-", "-" + safeName, directory);
        try (InputStream input = getContentResolver().openInputStream(uri);
             OutputStream stream = new FileOutputStream(output)) {
            if (input == null) {
                throw new IllegalStateException("Could not open selected file.");
            }
            byte[] buffer = new byte[64 * 1024];
            long copied = 0;
            int read;
            while ((read = input.read(buffer)) != -1) {
                if (copied > maximumBytes - read) {
                    throw new IllegalArgumentException("Selected file exceeds the size limit.");
                }
                stream.write(buffer, 0, read);
                copied += read;
            }
        } catch (Exception error) {
            if (!output.delete() && output.exists()) {
                output.deleteOnExit();
            }
            throw error;
        }
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("name", displayName);
        value.put("path", output.getPath());
        value.put("size", output.length());
        return value;
    }

    private void purgePickedFiles() {
        File directory = new File(getCacheDir(), "picked-files");
        File[] files = directory.listFiles();
        if (files == null) return;
        for (File file : files) {
            if (file.isFile()) file.delete();
        }
    }

    private String queryDisplayName(Uri uri) {
        try (Cursor cursor = getContentResolver().query(
                uri,
                new String[]{OpenableColumns.DISPLAY_NAME},
                null,
                null,
                null
        )) {
            if (cursor != null && cursor.moveToFirst()) return cursor.getString(0);
        }
        return uri.getLastPathSegment();
    }

    private Long queryFileSize(Uri uri) {
        try (Cursor cursor = getContentResolver().query(
                uri,
                new String[]{OpenableColumns.SIZE},
                null,
                null,
                null
        )) {
            if (cursor != null && cursor.moveToFirst() && !cursor.isNull(0)) {
                return cursor.getLong(0);
            }
        }
        return null;
    }

    private static String mimeTypeForExtension(String extension) {
        switch (extension.toLowerCase(Locale.ROOT)) {
            case "json":
                return "application/json";
            case "txt":
                return "text/plain";
            case "zip":
                return "application/zip";
            case "png":
                return "image/png";
            case "jpg":
            case "jpeg":
                return "image/jpeg";
            case "gif":
                return "image/gif";
            case "webp":
                return "image/webp";
            case "prism":
            default:
                return "application/octet-stream";
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
