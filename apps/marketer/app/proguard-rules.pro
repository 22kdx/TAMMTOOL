# Add project specific ProGuard rules here.
-keep class com.tammtool.marketerapp.** { *; }
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
-keep class com.tammtool.marketerapp.data.model.** { *; }
