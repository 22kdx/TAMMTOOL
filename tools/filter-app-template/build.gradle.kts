// المصفوفة مقفلة على نفس أرقام التطبيقين (AGP 8.6.1 + Kotlin 1.9.22 + Compose 1.5.8)
// أي تغيير هنا يجب أن يسري على apps/marketer و apps/orders-delivery في نفس الكوميت.
plugins {
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.22" apply false
}
