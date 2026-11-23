# Backup and restore: ways it can fail (written before the code)

Each line is a failure the backup code must survive, and what it does instead.

| # | Failure | Required behaviour |
|---|---|---|
| 1 | File is not JSON (photo, PDF, truncated download) | Refuse, "This isn't a Tipwell backup", data untouched |
| 2 | JSON but another app's file | Refuse on `format` mismatch |
| 3 | Made by a newer app version (`formatVersion` higher) | Refuse, "Update the app to restore this backup" |
| 4 | Edited by hand, or bytes lost | `sha256` of the data section doesn't match: refuse |
| 5 | Shift points at a job missing from the file | Refuse before deleting anything |
| 6 | Duplicate ids in the file | Refuse |
| 7 | Bad values (negative money, minutes 0 or over 24 h, bad day string) | Refuse, naming the first bad row |
| 8 | Restore fails half way (disk full, crash) | One transaction: either every row is replaced or none is |
| 9 | Person restores the wrong (older) file | Preview shows counts and date range first; a safety copy of current data is written before replacing, and is listed under automatic backups |
| 10 | App update changes the schema | Snapshot written before the upgrade step runs |
| 11 | Automatic backups pile up | Keep newest 14 automatic, newest 5 safety copies |
| 12 | Automatic backup runs on every launch | At most one per calendar day, plus after the first shift of the day |
| 13 | Writing a backup fails (storage full) | Error shown, database untouched, partial file deleted (write to .tmp, then rename) |
| 14 | Restoring an empty backup over real data | Allowed only after the preview says "0 shifts" in red and asks again |
| 15 | Database file itself is damaged | Launch health check (`integrity_check`, `foreign_key_check`) sends the person to a repair screen offering the newest automatic backup |
| 16 | Ids collide after restore with later inserts | Rows keep their ids; SQLite's autoincrement continues above the highest restored id |
