# تطبيق الفلتر — R8
# لا Room/Hilt هنا ⇒ لا kapt ⇒ فئة كاملة من أخطاء البناء مُلغاة (انظر AGENTS_STATUS.md «ر6» وGAP A1).
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*,Exceptions,SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# CameraX يستخدم reflection على بعض الفئات
-dontwarn androidx.camera.**

# أسماء الفلاتر تأتي من assets ولا يجب أن تُقلَّص
-keepclassmembers class com.tammtool.filterapp.domain.Filter { *; }

# مِظلّة أثناء اختبار التقليص فقط — احذفها لتفعيل R8 فعلاً
-keep class com.tammtool.filterapp.** { *; }
