# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in app/build.gradle.kts. You can edit this file to customize which
# classes are kept or obfuscated.

-keep class com.tammtool.app.** { *; }
-dontwarn androidx.**