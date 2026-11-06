# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in app/build.gradle.kts. You can edit this file to customize which
# classes are kept or obfuscated.

-keep class com.tammtool.ordersapp.** { *; }
-dontwarn androidx.**
-dontwarn com.google.android.material.**
-dontwarn kotlinx.serialization.**
-dontwarn dagger.**
-dontwarn androidx.hilt.**
-keepnames class * implements android.os.Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep class androidx.lifecycle.ViewModel { *; }
-keep class com.tammtool.ordersapp.data.model.** { *; }
