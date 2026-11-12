# Pay engine: ways it can be wrong

Written before the engine code. Each item names how it is prevented and which
scenario checks it (E = end-to-end test through the UI, I = isolated engine
scenario in test/pay_engine_scenarios_test.dart).

| # | Failure | Prevention | Check |
|---|---------|------------|-------|
| 1 | Overnight shift (22:00-07:00) lands on the wrong workday, so daily overtime is wrong | A shift belongs to the workday that contains its start | E, I-A |
| 2 | Shift crossing the week boundary (Sun 23:00-Mon 03:00) is split or counted in the wrong week | Whole shift goes to the week of its workday | E, I-A |
| 3 | Split shift (06-10 and 14-19) not added together for daily overtime | Daily totals run across all shifts of a workday in start order | E, I-A |
| 4 | Pyramiding: hours already paid as daily overtime also count toward the 40 h weekly limit | Only regular minutes feed the weekly counter | E, I-A |
| 5 | Weekly overtime given to the earliest hours instead of the hours past 40 | Minutes are allocated in time order | E, I-A, I-F |
| 6 | Double time (after 12 h) skipped, or applied before the 8 h band | Bands are cut in order: regular, then 1.5x up to the double limit, then 2x | E, I-A |
| 7 | Unpaid break subtracted twice, or a break longer than the shift gives negative pay | Break applied once per shift; validator rejects break >= span; engine clamps to 0 | I-H |
| 8 | Daylight saving: 22:00-06:00 on fall-back night is 9 h, spring-forward night 7 h; wall-clock maths says 8 h | Durations are taken between absolute instants, never wall-clock fields | I-B |
| 9 | Night workers with a 04:00 workday start see a 02:00 start counted as the next day | Configurable workday start minute per job | I-C |
| 10 | Rounding: floating point 1.5 x rate drifts; per-row rounding makes totals off | Integer cents x minutes x percent; totals rounded once from the exact sum | I-G |
| 11 | Changing the hourly rate reprices old shifts | Each shift stores its own rate when created | I-G |
| 12 | An open (still clocked-in) shift crashes the summary or counts as 0 / forever | Open shifts are excluded from pay until clocked out | E |
| 13 | Overlapping shifts in one job double-count time | Validator refuses to save an overlapping shift | E, I-I |
| 14 | Editing an end time to before the start gives negative hours | End at or before start on the same date rolls to the next day; > 24 h rejected | E |
| 15 | Rules turned off (no daily limit, or no weekly limit) break the maths | Each limit is optional and checked independently | I-D |
| 16 | Week start day (Sunday vs Monday) ignored | Per-job week start; grouping uses it | I-E |
| 17 | A report for part of a week recomputes weekly overtime from only the visible days and under-pays | Pay is computed on whole weeks, then the requested days are picked out | E, I-F |
| 18 | Overtime from two different jobs added together | Each job is computed on its own | E |
| 19 | California 7th-consecutive-day rule | Not supported in v1; stated in the app's help text | - |
