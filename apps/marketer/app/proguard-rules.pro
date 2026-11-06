# ── TAMMTOOL — قواعد R8/ProGuard ─────────────────────────────────────────────
# كانت القاعدة الوحيدة «-keep class com.tammtool.** { *; }» ⇒ كل كود التطبيق مستثنى من
# التقليص، أي minify=true بلا فائدة فعلية. القواعد الآن أضيق، مع مِظلّة في الأسفل تُبقي
# السلوك القديم إلى أن يُختبر التقليص على جهاز حقيقي (احذفها حينها).

-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*,Exceptions,SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Room — تنفيذ الـ DAO والمولّد من kapt
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.paging.**

# Hilt / Dagger
-dontwarn dagger.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# kotlinx.serialization — يحفظ الـ serializer المولّد لكل @Serializable
-dontnote kotlinx.serialization.**
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclassmembers class com.tammtool.** { *** Companion; }
-keep,includedescriptorclasses class com.tammtool.**$$serializer { *; }

# Compose — مرجع دوال التركيب لا يُقلَّص
-keep class androidx.compose.runtime.** { *; }
-dontwarn androidx.**

# مِظلّة أمان مؤقتة (S4 في GAP_TO_APK.md): احذفها لتفعيل التقليص فعلاً
-keep class com.tammtool.** { *; }
