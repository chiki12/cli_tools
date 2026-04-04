# rlog - Research Journal CLI

## Setup

```bash
# Copy to somewhere in your PATH
sudo cp rlog /usr/local/bin/rlog
# or
cp rlog ~/bin/rlog && export PATH="$HOME/bin:$PATH"

# Optional: change log directory (default: ~/research-log)
echo 'export RLOG_DIR="$HOME/research-log"' >> ~/.bashrc
```

## Commands

| Command | What it does |
|---|---|
| `rlog run <cmd>` | Run command, auto-detect input/output files, log everything |
| `rlog exp` | Interactive experiment entry (model, method, config, result, tags) |
| `rlog env [memo]` | Snapshot conda env, python, GPU, key packages |
| `rlog data <path> [memo]` | Record where data/outputs live |
| `rlog note <text>` | Free-form note |
| `rlog today` | View today's log |
| `rlog yesterday` | View yesterday's log |
| `rlog show [n]` | View recent entries |
| `rlog search <keyword>` | Search across all days |
| `rlog tags` | List all `#tags` with counts |
| `rlog tag <name>` | Filter entries by tag |
| `rlog list` | List all logged dates |

## Examples

```bash
# Log a command with auto file detection
rlog run ffmpeg -i session3.mp4 -vn session3_audio.wav
rlog run python sam2_pipeline.py --input video.mp4 --output masks/
rlog run mv results/old.npz backup/old.npz

# Log an experiment
rlog exp
# → prompts for: Model, Method/Config, Input, Output, Result, Tags, Notes

# Snapshot your environment
rlog env "SAM2 pipeline env"

# Record data location
rlog data /data/outputs/session3_masks.npz "all 4 sessions done"

# Notes with tags
rlog note "chunk_size=100 で安定動作 #sam2 #memory"
rlog note "switched to OSNet for Re-ID #torchreid"

# Review
rlog today
rlog search OOM
rlog tag sam2
```

## File Structure

```
~/research-log/
├── index.md              # Auto-updated date index
├── days/
│   ├── 2026-04-01.md     # One file per day
│   ├── 2026-04-02.md
│   └── 2026-04-04.md
└── envs/
    ├── 2026-04-01_sam2.txt    # pip freeze snapshots
    └── 2026-04-04_system.txt
```

## Tips

- Use `#tags` in notes/experiments to organize by topic
- Run `rlog env` whenever you switch conda environments
- `rlog data` is great for recording where generated `.npz` / masks / models end up
- Works over SSH — log on remote server, review later
