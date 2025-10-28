# ==================== Flutter Rules ====================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# ==================== Firebase Rules ====================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging specific
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.remoteconfig.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firebase Performance
-keep class com.google.firebase.perf.** { *; }
-keep class com.google.android.gms.internal.firebase.perf.** { *; }
-keep class com.google.firebase.perf.metrics.** { *; }
-keep class com.google.firebase.perf.internal.** { *; }
-dontwarn com.google.firebase.perf.**

# Firebase In-App Messaging
-keep class com.google.firebase.inappmessaging.** { *; }
-keep class com.google.firebase.inappmessaging.display.** { *; }
-keep class com.google.firebase.inappmessaging.display.internal.** { *; }
-dontwarn com.google.firebase.inappmessaging.**

# ==================== Notification Classes ====================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ==================== App Specific Classes ====================
-keep class com.dhakarani1.app.** { *; }
-keep class com.dhakarani1.app.MainActivity { *; }
-keep class com.dhakarani1.app.MyFirebaseMessagingService { *; }
-keep class com.dhakarani1.app.DoNotDisturbHandler { *; }

# ==================== Kotlin Rules ====================
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# Kotlin Metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ==================== Protobuf Rules ====================
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# ==================== JSON/Gson Rules ====================
-keepattributes Signature
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# ==================== Native Methods ====================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ==================== Enums ====================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ==================== Serializable ====================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==================== Parcelable ====================
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ==================== WebView ====================
-keepclassmembers class fqcn.of.javascript.interface.for.webview {
    public *;
}

# ==================== Remove Logs (Release Only) ====================
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ==================== OkHttp/Retrofit ====================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# ==================== AndroidX ====================
-keep class androidx.** { *; }
-dontwarn androidx.**

# ==================== WorkManager ====================
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# ==================== General Rules ====================
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# تجنب تحذيرات غير مهمة
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose