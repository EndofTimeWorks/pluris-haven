package works.endoftime.plurishaven

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveSource: String? = null

    private val pickLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { activityResult ->
        val result = pendingPickResult ?: return@registerForActivityResult
        pendingPickResult = null
        if (activityResult.resultCode != Activity.RESULT_OK) {
            result.success(null)
            return@registerForActivityResult
        }
        try {
            val intent = activityResult.data
            val uris = selectedUris(intent)
            result.success(uris.map { copySelectionToCache(it) })
        } catch (error: Exception) {
            result.error("pick_failed", error.message, null)
        }
    }

    private val saveLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { activityResult ->
        val result = pendingSaveResult ?: return@registerForActivityResult
        val sourcePath = pendingSaveSource
        pendingSaveResult = null
        pendingSaveSource = null
        if (activityResult.resultCode != Activity.RESULT_OK || sourcePath == null) {
            result.success(false)
            return@registerForActivityResult
        }
        val destination = activityResult.data?.data
        if (destination == null) {
            result.success(false)
            return@registerForActivityResult
        }
        try {
            File(sourcePath).inputStream().use { input ->
                contentResolver.openOutputStream(destination, "w").use { output ->
                    requireNotNull(output) { "Could not open the selected destination." }
                    input.copyTo(output)
                }
            }
            result.success(true)
        } catch (error: Exception) {
            result.error("save_failed", error.message, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "works.endoftime.plurishaven/file_dialog",
        ).setMethodCallHandler(::handleFileDialogCall)
    }

    private fun handleFileDialogCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFiles" -> openFileDialog(call, result)
            "saveFile" -> openSaveDialog(call, result)
            else -> result.notImplemented()
        }
    }

    private fun openFileDialog(call: MethodCall, result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("picker_busy", "A file picker is already open.", null)
            return
        }
        val type = call.argument<String>("type")
        val extensions = call.argument<List<String>>("allowedExtensions").orEmpty()
        val allowMultiple = call.argument<Boolean>("allowMultiple") == true
        val mimeTypes = when (type) {
            "image" -> arrayOf("image/*")
            else -> extensions.map(::mimeTypeForExtension).distinct().toTypedArray()
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            this.type = if (mimeTypes.size == 1) mimeTypes.first() else "*/*"
            if (mimeTypes.isNotEmpty()) putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
        }
        pendingPickResult = result
        pickLauncher.launch(intent)
    }

    private fun openSaveDialog(call: MethodCall, result: MethodChannel.Result) {
        if (pendingSaveResult != null) {
            result.error("picker_busy", "A save dialog is already open.", null)
            return
        }
        val sourcePath = call.argument<String>("sourcePath")
        val fileName = call.argument<String>("fileName")
        if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
            result.error("invalid_save", "Missing export source or filename.", null)
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = call.argument<String>("mimeType") ?: "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        pendingSaveResult = result
        pendingSaveSource = sourcePath
        saveLauncher.launch(intent)
    }

    private fun selectedUris(intent: Intent?): List<Uri> {
        val uris = mutableListOf<Uri>()
        intent?.data?.let(uris::add)
        val clipData: ClipData? = intent?.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                val uri = clipData.getItemAt(index).uri
                if (uri != null && uri !in uris) uris.add(uri)
            }
        }
        return uris
    }

    private fun copySelectionToCache(uri: Uri): Map<String, Any> {
        val displayName = queryDisplayName(uri) ?: "selected-file"
        val safeName = displayName.replace(Regex("[^A-Za-z0-9._ -]"), "_")
        val directory = File(cacheDir, "picked-files").apply { mkdirs() }
        val output = File.createTempFile("picked-", "-$safeName", directory)
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Could not open selected file." }
            output.outputStream().use(input::copyTo)
        }
        return mapOf("name" to displayName, "path" to output.path, "size" to output.length())
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null).use { cursor ->
            if (cursor != null && cursor.moveToFirst()) {
                return cursor.getString(0)
            }
        }
        return uri.lastPathSegment
    }

    private fun mimeTypeForExtension(extension: String): String = when (extension.lowercase()) {
        "json", "txt" -> "text/plain"
        "zip" -> "application/zip"
        "prism" -> "application/octet-stream"
        "png" -> "image/png"
        "jpg", "jpeg" -> "image/jpeg"
        "gif" -> "image/gif"
        "webp" -> "image/webp"
        else -> "application/octet-stream"
    }
}
