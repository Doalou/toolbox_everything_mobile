package com.toolbox.everything.mobile

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.toolbox.everything.mobile/downloads")
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
            // Derive absolute path when possible (not strictly necessary)
            itemUri.toString()
        } else {
            // Legacy: write directly to public Downloads
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
        val uri = android.net.Uri.parse(uriStr)
        var resolvedMime = mimeType
        if (resolvedMime.isNullOrBlank() || resolvedMime == "*/*" || resolvedMime == "application/octet-stream") {
            try {
                resolvedMime = applicationContext.contentResolver.getType(uri)
            } catch (_: Exception) {}
        }
        if (resolvedMime.isNullOrBlank()) {
            // Heuristique minimale si type introuvable
            resolvedMime = if (uriStr.contains("/video", ignoreCase = true)) "video/*"
            else if (uriStr.contains("/audio", ignoreCase = true)) "audio/*"
            else "*/*"
        }

        val baseIntent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
            setDataAndType(uri, resolvedMime)
            addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val candidates = listOf(
            "org.videolan.vlc",               // VLC
            "com.mxtech.videoplayer.ad",      // MX Player (free)
            "com.mxtech.videoplayer.pro"      // MX Player Pro
        )
        for (pkg in candidates) {
            try {
                val intent = android.content.Intent(baseIntent).apply { setPackage(pkg) }
                startActivity(intent)
                return
            } catch (_: Exception) {
                // try next
            }
        }

        val chooser = android.content.Intent.createChooser(baseIntent, "Ouvrir avec")
        startActivity(chooser)
    }
}
