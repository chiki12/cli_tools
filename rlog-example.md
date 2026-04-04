# rlog Workflow Example: Iterative Conv Environment

A walkthrough of using `rlog` across a real session — building a convolution training
environment, iterating through failures, and tracking what changed at each step.

---

## Start a named session

Before anything else, start a session for this work:

```bash
rlog session start "conv2d experiment"
# ✓ session started: conv2d experiment
```

All log entries in this terminal are now grouped under `## Session: conv2d experiment`
in the day file. If you close the terminal and come back tomorrow:

```bash
rlog session start "conv2d experiment"
# ✓ resumed session: conv2d experiment (started 2026-04-05 10:00:00)
```

Same session name — picks up where you left off, in today's day file.

If you want to pause without ending the session (e.g. switch to a different task in
a new terminal):

```bash
rlog session end
# ✓ detached from: conv2d experiment  (resume with: rlog session start "conv2d experiment")
```

The session record is preserved. Entries logged without an active session go under
`## Session: others` automatically.

To see what session is active in the current terminal:

```bash
rlog session status
# Active session: conv2d experiment (started 2026-04-05 10:00:00)
```

To see all sessions across all terminals:

```bash
rlog session list
#   conv2d experiment              started 2026-04-05 10:00:00 [attached]
#   data cleaning                  started 2026-04-04 14:30:00
```

When a project is fully done and you don't need the session record anymore:

```bash
rlog session delete "conv2d experiment"
# ✓ session deleted: conv2d experiment
```

---

## Setup: Snapshot your environment

Before writing a single line of code, capture your environment:

```bash
rlog env "starting conv2d experiment"
```

Logs Python version, conda/venv, GPU info, and key pip packages. Saved to
`~/research-log/envs/`. You'll thank yourself when debugging a dependency issue
three weeks later.

---

## The iteration loop

### Attempt 1 — Run, fail, note what you're changing

```bash
rlog run python train_conv.py --config cfg_v1.yaml
```

Output streams to your terminal as usual. When the command finishes:

```
Save output to log? [y/n/t] (y=full, n=skip output, t=truncated) [Y]:
```

For a failed run with a short traceback → **`t`** (truncated, head+tail).
You just need the error, not 300 lines of dataloader output.

Then, before your next attempt, note what you changed:

```bash
rlog note "OOM on first run. Reduced batch_size 64→16 #conv2d #fix"
```

**Log it before you run.** That way the note sits above the next result in the timeline.

---

### Attempt 2 — Still failing, different error

```bash
rlog run python train_conv.py --config cfg_v1.yaml
# → save: t
```

```bash
rlog note "NaN loss after epoch 2. Added gradient clipping max_norm=1.0 #conv2d"
```

---

### Attempt 3 — It works

```bash
rlog run python train_conv.py --config cfg_v1.yaml
# → save: y  ← capture the full successful output
```

Full output is wrapped in a collapsible `<details>` block in the markdown log.
Exit code `0` is recorded.

---

## Record the output files

The successful run produced a checkpoint and a metrics file. Log them:

```bash
rlog data outputs/conv_v1_best.pth "best checkpoint, val_acc=89.1%"
rlog data results/conv_v1_metrics.csv "per-class accuracy breakdown"
```

Logs the absolute path, file size, and your memo — so you know what each file is
months later without opening it.

---

## Write the experiment summary

Now capture the full picture while it's fresh:

```bash
rlog exp
```

Interactive prompts:

```
Model/Tool:          ResNet18 + custom Conv2D
Method/Config:       kernel=3, no BN, lr=1e-3, batch=16
Input data:          /data/cifar10/train
Output data:         outputs/conv_v1_best.pth
Result:              val_acc=89.1%, converged epoch 61
Tags:                #conv2d #cifar10 #v1
Extra notes:         OOM fixed by batch_size 16. NaN fixed by grad clip.
```

This creates a clean summary table entry — useful for writing up results or
comparing across runs.

---

## Change the architecture and compare

Now you switch to depthwise separable convolutions:

```bash
rlog note "v2: replacing standard conv with depthwise separable conv. Expect lower param count #conv2d #v2"

rlog run python train_conv.py --config cfg_v2.yaml
# → save: y
```

After success:

```bash
rlog data outputs/conv_v2_best.pth "depthwise sep, val_acc=91.4%, 40% fewer params"
rlog exp
```

---

## Review your session

**Everything from today, in order:**

```bash
rlog today
```

You'll see the full timeline, grouped by session:

```
## Session: conv2d experiment

### [10:02] env snapshot
### [10:15] cmd `python train_conv.py --config cfg_v1.yaml`   exit: 1
### [10:18] note: OOM on first run. Reduced batch_size 64→16
### [10:20] cmd `python train_conv.py --config cfg_v1.yaml`   exit: 1
### [10:22] note: NaN loss. Added gradient clipping
### [10:31] cmd `python train_conv.py --config cfg_v1.yaml`   exit: 0  ✓
### [10:33] data: outputs/conv_v1_best.pth
### [10:34] experiment: ResNet18 + custom Conv2D
### [10:51] note: v2 depthwise separable conv
### [11:14] cmd `python train_conv.py --config cfg_v2.yaml`   exit: 0  ✓

## Session: others

### [13:05] cmd `echo quick test`   exit: 0
```

**Search across all past sessions:**

```bash
rlog search conv2d          # all entries mentioning conv2d
rlog search "val_acc"       # all accuracy results ever logged
rlog tag conv2d             # entries tagged #conv2d
```

**Browse recent entries across multiple days:**

```bash
rlog show 20
```

---

## Clean up mistakes

Accidentally logged a junk test run:

```bash
rlog delete last
# Last entry:
# ### [11:02] cmd `python scratch_test.py`
# Delete? [y/N]: y
# ✓ deleted
```

Delete a specific numbered entry (check numbers with `rlog today | grep '^### '`):

```bash
rlog delete today 3
# Entry #3 from 2026-04-05:
# ### [10:20] cmd `python train_conv.py ...`
# Delete? [y/N]: n
# Aborted.
```

Delete an entire day (e.g. a throwaway exploration session):

```bash
rlog delete day 2026-04-03
# Delete entire day 2026-04-03 (7 entries)? [y/N]: y
# ✓ deleted 2026-04-03
```

---

## Command reference

| Situation | Command |
|---|---|
| Start a named session | `rlog session start "name"` |
| Resume session in new terminal | `rlog session start "name"` (same command) |
| Detach session (preserve it) | `rlog session end` |
| Check active session | `rlog session status` |
| List all sessions | `rlog session list` |
| Permanently remove session | `rlog session delete "name"` |
| Snapshot environment | `rlog env "memo"` |
| Running code (any attempt) | `rlog run <cmd>` → pick y / t / n |
| Explain what you changed | `rlog note "..."` |
| Experiment done, full summary | `rlog exp` |
| Note an output file | `rlog data <path> "memo"` |
| Review today | `rlog today` |
| Find old experiments | `rlog search <keyword>` |
| Filter by tag | `rlog tag <name>` |
| Remove last entry | `rlog delete last` |
| Remove specific entry | `rlog delete <date> <n>` |
| Remove whole day | `rlog delete day [date]` |

---

## The one habit that makes it useful

**Note before you run.**

When you look back at a log entry showing `exit 0`, you want the note just above it
explaining *what change made it work*. If you log the note after, the timeline
reads as: ran → worked — with no explanation of why.
