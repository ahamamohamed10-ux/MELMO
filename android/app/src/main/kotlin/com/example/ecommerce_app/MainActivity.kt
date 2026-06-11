package com.example.ecommerce_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 🔥 Injection directe du jeton de débogage Firebase App Check
        System.setProperty("firebase.appcheck.debug.token", "AFFE14F4-EA84-432F-BCDB-499AB7987DE3")
        
        super.onCreate(savedInstanceState)
    }
}