# s3local Command Reference

A quick reference for common SSH and `rsync` operations when using the `s3local` archive server.

Assumptions:

- SSH alias: `s3local`
- Archive directory: `/archive`
- SSH configuration is already present in `~/.ssh/config`

---

# Connect to the Server

```bash
ssh s3local
```

---

# Verify Disk Space

```bash
ssh s3local df -h /archive
```

---

# List Archived Files

```bash
ssh s3local ls -lah /archive
```

---

# Show Archive Size

```bash
ssh s3local du -sh /archive
```

---

# Upload a Single File

```bash
rsync -avP myfile.txt s3local:/archive/
```

---

# Upload Multiple Files

```bash
rsync -avP *.mp4 s3local:/archive/
```

---

# Upload an Entire Directory

```bash
rsync -avP Videos/ s3local:/archive/Videos/
```

---

# Upload Large Files (Recommended)

```bash
rsync -avP \
    --append-verify \
    huge-video.mp4 \
    s3local:/archive/
```

---

# Upload Everything in Current Directory

```bash
rsync -avP ./ s3local:/archive/
```

---

# Resume an Interrupted Transfer

Simply rerun the same command:

```bash
rsync -avP \
    --append-verify \
    huge-video.mp4 \
    s3local:/archive/
```

`rsync` resumes from where it stopped.

---

# Download a File

```bash
rsync -avP s3local:/archive/myfile.txt .
```

---

# Download an Entire Directory

```bash
rsync -avP \
    s3local:/archive/Videos/ \
    ./Videos/
```

---

# Synchronize a Local Directory

```bash
rsync -avP \
    Photos/ \
    s3local:/archive/Photos/
```

Only changed files are transferred.

---

# Preview a Transfer

```bash
rsync -av \
    --dry-run \
    Photos/ \
    s3local:/archive/Photos/
```

Nothing is copied.

---

# Mirror a Directory

```bash
rsync -av \
    --delete \
    Photos/ \
    s3local:/archive/Photos/
```

⚠ **Warning:** Files deleted locally will also be deleted remotely.

Always test first:

```bash
rsync -av --dry-run --delete \
    Photos/ \
    s3local:/archive/Photos/
```

---

# Exclude Files

```bash
rsync -avP \
    --exclude '*.tmp' \
    --exclude '.DS_Store' \
    source/ \
    s3local:/archive/source/
```

---

# Limit Bandwidth

```bash
rsync -avP \
    --bwlimit=20M \
    source/ \
    s3local:/archive/source/
```

---

# Compare Using Checksums

```bash
rsync -avc \
    source/ \
    s3local:/archive/source/
```

Useful when timestamps cannot be trusted.

---

# Show Transfer Statistics

```bash
rsync -avP \
    --stats \
    source/ \
    s3local:/archive/source/
```

---

# Verify Server Identity

```bash
ssh-keygen -F s3local
```

---

# Remove Old SSH Host Key

```bash
ssh-keygen -R "[s3local]:2222"
```

---

# Verify SSH Configuration

```bash
ssh -G s3local
```

---

# Common rsync Options

| Option | Description |
|---------|-------------|
| `-a` | Archive mode (recursive, preserve metadata) |
| `-v` | Verbose |
| `-h` | Human-readable sizes |
| `-P` | Progress + keep partial files |
| `--append-verify` | Resume interrupted transfers safely |
| `--progress` | Display progress |
| `--partial` | Keep partial files |
| `--delete` | Remove files from destination not present in source |
| `--dry-run` | Preview changes |
| `--exclude` | Skip matching files |
| `--stats` | Display transfer statistics |
| `--checksum` (`-c`) | Compare using checksums |

---

# Recommended Commands

### Upload a Large Video

```bash
rsync -avP \
    --append-verify \
    movie.mp4 \
    s3local:/archive/
```

---

### Upload a Project

```bash
rsync -avP \
    project/ \
    s3local:/archive/project/
```

---

### Upload Photos

```bash
rsync -avP \
    Photos/ \
    s3local:/archive/Photos/
```

---

### Restore a Directory

```bash
rsync -avP \
    s3local:/archive/project/ \
    ./project/
```

---

# Trailing Slash Reminder

```bash
rsync -avP Photos s3local:/archive/
```

Copies:

```text
/archive/Photos/
```

Whereas:

```bash
rsync -avP Photos/ s3local:/archive/Photos/
```

Copies only the **contents** of `Photos` into the destination directory.

---

# Best Practices

- Use `rsync` instead of `scp` for almost all file transfers.
- Use `-P` for visibility and automatic resume support.
- Add `--append-verify` for large files that may be interrupted.
- Use `--dry-run` before running any command with `--delete`.
- Keep private SSH keys secure and never commit them to version control.
- Use the SSH alias (`s3local`) instead of remembering IP addresses or ports.
