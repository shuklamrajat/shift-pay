# Release-only keep rules (R8 runs on release builds only).
#
# Google Mobile Ads pulls in WorkManager, which androidx.startup initialises
# as the app process starts. WorkManager creates its Room database by
# reflection (WorkDatabase_Impl, no-arg constructor). Without these rules R8
# removes or merges that class and every release build crashes before the
# first frame with "Failed to create an instance of
# androidx.work.impl.WorkDatabase" (Wagebird v11 / Wrenchnote v10, Nov 13).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
