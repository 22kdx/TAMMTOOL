# مثال: Hello World (تطبيق تجريبي)

تطبيق بسيط لتجربة دورة البناء والتوقيع والنشر باستخدام مستودع TAMMTOOL.

## كيفية التجربة

```bash
cd examples/hello-world

# فحص البيئة
bash ../scripts/check-env.sh

# بناء نسخة التصحيح
bash ../scripts/build-apk.sh debug app

# تثبيت على الجهاز المتصل
adb install app/build/outputs/apk/debug/app-debug.apk

# بناء نسخة الإصدار
bash ../scripts/build-apk.sh release app

# توقيع ملف الإصدار (سيُطلب منك كلمات المرور)
bash ../scripts/sign-apk.sh \
  app/build/outputs/apk/release/app-release-unsigned.apk \
  ../keystore/release-keystore.jks \
  release-key \
  app/build/outputs/apk/release/app-release.apk
```

## ملاحظة

هذا المثال للتعلم فقط. قبل نشر أي تطبيق على متجر Google Play، تأكد من:
- إنشاء keystore خاص وآمن وحفظه خارج المستودع.
- تحديث `applicationId` و `versionCode` و `versionName`.
- إضافة سياسة الخصوصية ولقطات الشاشة المطلوبة من Google Play.

راجع دوائر العمل في `docs/` للتفاصيل الكاملة.