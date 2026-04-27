# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# OkHttp / Retrofit (utilisé par http package)
-dontwarn okhttp3.**
-dontwarn okio.**

# Sérialisation JSON
-keepattributes Signature
-keepattributes *Annotation*
-keep class * implements java.io.Serializable { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }
