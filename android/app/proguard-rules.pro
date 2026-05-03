# 1. Flutter Engine & Plugins
# Prevents R8 from stripping core Flutter classes and plugin interfaces
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Firebase & Google Play Services
# Essential for App Check, Firestore, and Authentication in release builds
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# 3. Google Play Core & Play Integrity (Critical for App Check)
# Fixes "Missing Class" errors and ensures Play Integrity works in the background
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# 4. Standard Library & Coroutines
# Protects Kotlin features often used by modern Flutter plugins
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-keep class kotlin.reflect.jvm.internal.** { *; }

# 5. General Optimization Rules
-ignorewarnings
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes Signature
-keepattributes InnerClasses