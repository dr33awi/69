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

# ==================== Notification Classes ====================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ==================== App Specific Classes ====================
-keep class com.example.test_athkar_app.** { *; }
-keep class com.example.test_athkar_app.MainActivity { *; }
-keep class com.example.test_athkar_app.MyFirebaseMessagingService { *; }
-keep class com.example.test_athkar_app.DoNotDisturbHandler { *; }

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

# ==================== OkHttp/Retrofit (إذا استخدم) ====================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# ==================== AndroidX ====================
-keep class androidx.** { *; }
-dontwarn androidx.**

# ==================== General Rules ====================
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# تجنب تحذيرات غير مهمة
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**