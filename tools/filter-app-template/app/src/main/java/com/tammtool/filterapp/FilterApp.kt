package com.tammtool.filterapp

import android.app.Application

/**
 * Application بلا Hilt وبلا قاعدة بيانات — لا شيء يُفعَّل عند الإقلاع غير ضبط الاتجاه/الثيم.
 * إن أضفت Timber لاحقاً فاضبطه هنا (الإعلان وحده عن مكتبة لا يكفي — GAP_TO_APK.md C7).
 */
class FilterApp : Application()
