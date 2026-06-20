# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson (used by Firebase)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Gemini / Google Generative AI
-keep class com.google.generativeai.** { *; }
-keep interface com.google.generativeai.** { *; }
-dontwarn com.google.generativeai.**

# Riverpod
-keep class com.cadre_upsc.features.auth.providers.** { *; }
-keep class * extends androidx.lifecycle.ViewModel { *; }

# Hive (Storage)
-keep class com.mongodb.client.model.** { *; }
-keep class io.hive.** { *; }

# Kotlin / Desugaring
-dontwarn java.lang.invoke.*
-dontwarn **$$ExternalSyntheticLambda0
-dontwarn **$$ExternalSyntheticLambda1
-dontwarn **$$ExternalSyntheticLambda2

# Play Core (Deferred Components - referenced by Flutter but optional)
-dontwarn com.google.android.play.core.**
