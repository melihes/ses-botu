package com.esmgames.reyting

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Teşhis: bu kopyanın gerçek imza sertifikaları (Google girişi için Firebase'e kaydedilmesi gereken)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "reyting/cert").setMethodCallHandler { call, result ->
            if (call.method != "fingerprints") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val out = mutableListOf<String>()
                fun sha1(b: ByteArray): String =
                    MessageDigest.getInstance("SHA-1").digest(b).joinToString(":") { "%02X".format(it) }
                @Suppress("DEPRECATION")
                val old = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
                old?.forEachIndexed { i, s -> out.add("signatures[$i]=" + sha1(s.toByteArray())) }
                if (Build.VERSION.SDK_INT >= 28) {
                    val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo
                    if (info != null) {
                        if (info.hasMultipleSigners()) {
                            info.apkContentsSigners.forEachIndexed { i, s -> out.add("signer[$i]=" + sha1(s.toByteArray())) }
                        } else {
                            info.signingCertificateHistory.forEachIndexed { i, s -> out.add("history[$i]=" + sha1(s.toByteArray())) }
                        }
                    }
                }
                result.success(out)
            } catch (e: Exception) {
                result.success(listOf("hata: ${e.message}"))
            }
        }
    }
}
