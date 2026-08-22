package com.tajikshop.app

import android.os.Build
import android.os.Bundle
import android.view.View
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Autofill-ро барои тамоми барнома хомӯш мекунем — дар MIUI/Xiaomi
        // ин highlight-и хокистаранги майдонҳои матн (email/парол)-ро нест мекунад.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.decorView.importantForAutofill =
                View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
        }
    }
}
