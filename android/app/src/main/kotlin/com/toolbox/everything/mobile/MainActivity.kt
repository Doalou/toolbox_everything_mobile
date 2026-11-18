package com.toolbox.everything.mobile

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val DOWNLOADS_CHANNEL = "com.toolbox.everything.mobile/downloads"
        private const val SHARE_CHANNEL = "com.toolbox.everything.mobile/share"
    }

    private var shareChannel: MethodChannel? = null
    private var pendingSharedPayload: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractSharePayload(intent)?.let {
            pendingSharedPayload = it
            setIntent(Intent(Intent.ACTION_MAIN))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = extractSharePayload(intent) ?: return
        setIntent(Intent(Intent.ACTION_MAIN))
        val channel = shareChannel
        if (channel != null) {
            channel.invokeMethod("onNewShare", payload)
        } else {
            pendingSharedPayload = payload
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requiresLegacyStoragePermission" -> {
                        result.success(Build.VERSION.SDK_INT <= Build.VERSION_CODES.P)
                    }
                    "saveToDownloads" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val displayName = call.argument<String>("displayName")
                        val mimeType = call.argument<String>("mimeType")
                        if (sourcePath == null || displayName == null) {
                            result.error("ARG_ERROR", "Missing arguments", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveFileToDownloads(this, sourcePath, displayName, mimeType)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.message, null)
                        }
                    }
                    "openContentUri" -> {
                        val uriStr = call.argument<String>("uri")
                        val mimeType = call.argument<String>("mimeType")
                        if (uriStr == null) {
                            result.error("ARG_ERROR", "Missing uri", null)
                            return@setMethodCallHandler
                        }
                        try {
                            openContentUri(uriStr, mimeType)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeInitialShare" -> {
                        result.success(pendingSharedPayload)
                        pendingSharedPayload = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun extractSharePayload(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val streamUri = readStreamUri(intent)
                val extraText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (streamUri != null) {
                    val copied = copySharedUriToCache(streamUri, intent.type)
                    if (copied != null) {
                        mapOf(
                            "type" to "file",
                            "filePath" to copied.first.absolutePath,
                            "fileName" to copied.second,
                            "mimeType" to (contentResolver.getType(streamUri) ?: intent.type),
                            "text" to extraText,
                        )
                    } else if (!extraText.isNullOrBlank()) {
                        mapOf("type" to "text", "text" to extraText)
                    } else {
                        null
                    }
                } else if (!extraText.isNullOrBlank()) {
                    mapOf("type" to "text", "text" to extraText)
                } else {
                    null
                }
            }
            Intent.ACTION_PROCESS_TEXT -> {
                val processText = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                if (!processText.isNullOrBlank()) {
                    mapOf("type" to "text", "text" to processText)
                } else {
                    null
                }
            }
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                if (uri != null && uri.scheme.equals("toolbox", ignoreCase = true)) {
                    val text = uri.getQueryParameter("url")
                        ?: uri.getQueryParameter("text")
                        ?: uri.toString()
                    mapOf(
                        "type" to "text",
                        "text" to text,
                        "target" to uri.host,
                    )
                } else {
                    null
                }
            }
            else -> null
        }
    }

    private fun readStreamUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        }
    }

    private fun copySharedUriToCache(uri: Uri, fallbackMime: String?): Pair<File, String>? {
        return try {
            val rawName = resolveDisplayName(uri, fallbackMime)
            val safeName = rawName.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val importDir = File(cacheDir, "shared_imports")
            if (!importDir.exists()) {
                importDir.mkdirs()
            } else {
                val cutoff = System.currentTimeMillis() - 86_400_000L
                importDir.listFiles()?.forEach { child ->
                    if (child.isFile && child.lastModified() < cutoff) {
                        child.delete()
                    }
                }
            }
            val targetFile = File(importDir, "${System.currentTimeMillis()}_$safeName")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            Pair(targetFile, rawName)
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveDisplayName(uri: Uri, fallbackMime: String?): String {
        var name: String? = null
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) {
                        name = cursor.getString(idx)
                    }
                }
            }
        } catch (_: Exception) {}
        if (!name.isNullOrBlank()) return name!!
        val lastSeg = uri.lastPathSegment?.substringAfterLast('/')
        if (!lastSeg.isNullOrBlank() && lastSeg.contains('.')) return lastSeg
        val mime = contentResolver.getType(uri) ?: fallbackMime
        val ext = if (mime != null) MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) else null
        return if (!ext.isNullOrBlank()) "shared_file.$ext" else "shared_file"
    }

    private fun saveFileToDownloads(
        context: Context,
        sourcePath: String,
        displayName: String,
        mimeType: String?
    ): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) throw IllegalArgumentException("Source file not found")

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType ?: "application/octet-stream")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = context.contentResolver
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val itemUri: Uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("Failed to create MediaStore record")
            resolver.openOutputStream(itemUri)?.use { out ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(out)
                }
            } ?: throw IllegalStateException("Failed to open output stream")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
            itemUri.toString()
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val outFile = File(downloadsDir, displayName)
            FileInputStream(sourceFile).use { input ->
                FileOutputStream(outFile).use { out ->
                    input.copyTo(out)
                }
            }
            outFile.absolutePath
        }
    }

    private fun openContentUri(uriStr: String, mimeType: String?) {
        val uri = Uri.parse(uriStr)
        var resolvedMime = mimeType
        if (resolvedMime.isNullOrBlank() || resolvedMime == "*/*" || resolvedMime == "application/octet-stream") {
            try {
                resolvedMime = applicationContext.contentResolver.getType(uri)
            } catch (_: Exception) {}
        }
        if (resolvedMime.isNullOrBlank()) {
            resolvedMime = if (uriStr.contains("/video", ignoreCase = true)) "video/*"
            else if (uriStr.contains("/audio", ignoreCase = true)) "audio/*"
            else "*/*"
        }

        val baseIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, resolvedMime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val candidates = listOf(
            "org.videolan.vlc",
            "com.mxtech.videoplayer.ad",
            "com.mxtech.videoplayer.pro"
        )
        for (pkg in candidates) {
            try {
                val intent = Intent(baseIntent).apply { setPackage(pkg) }
                startActivity(intent)
                return
            } catch (_: Exception) {}
        }

        val chooser = Intent.createChooser(baseIntent, "Ouvrir avec")
        startActivity(chooser)
    }
}
