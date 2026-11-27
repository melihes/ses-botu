# WorkManager/Room (reklam SDK'sı üzerinden gelir): veritabanı sınıfları
# yansıma ile oluşturulur, küçültmede silinmesin.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
