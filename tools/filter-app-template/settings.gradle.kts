// تطبيق الفلتر — مشروع Gradle مستقل مثل التطبيقين الشقيقين
// يُولَّد من tools/scaffold-filter-app.sh — عدّله هنا بعد التوليد ولا تُعدّل المولّد لكل تفصيل
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "FilterApp"
include(":app")
