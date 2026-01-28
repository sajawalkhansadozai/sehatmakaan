# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.common.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Stripe SDK - Keep all Stripe classes
-keep class com.stripe.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.**
-dontwarn com.reactnativestripesdk.**

# Keep Stripe push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep interface com.stripe.android.pushProvisioning.** { *; }

# PayFast
-keep class com.payfast.** { *; }
-dontwarn com.payfast.**

# Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-dontwarn com.google.gson.**

# Retrofit
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-dontwarn retrofit2.**
-dontwarn okhttp3.**

# OkHttp3
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Image libraries
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Additional keep rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class * implements android.os.Parcelable { *; }
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
}
