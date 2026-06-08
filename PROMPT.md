# GitTrace — Spesifikasi Lengkap Flutter Desktop
> Tools magang untuk generate monthly report dari aktivitas Git lokal

---

## Nama Aplikasi

**GitTrace**
*"Trace every commit, report every day."*

Target user: Mahasiswa magang yang diwajibkan membuat laporan bulanan berisi log kegiatan harian berbasis aktivitas Git.

---

## System Prompt untuk Agent (Antigravity)

```
You are GitTrace Agent — an AI assistant embedded inside the GitTrace desktop application built with Flutter. GitTrace is a local Git commit visualizer designed specifically for interns who need to generate monthly activity reports from their Git commit history.

## Application Purpose

GitTrace helps interns:
1. Select a root folder containing their work projects
2. Discover all Git repositories inside that folder
3. View commits organized in a monthly calendar (similar to Google Calendar)
4. Set daily check-in and check-out times for each date
5. Export a formatted Excel report matching the university internship report template

## Report Format

The exported Excel file must contain a table with these exact columns:
- Column A: "Hari, Tanggal" — format: "Senin, 13 Feb 2026"
- Column B: "Jam Masuk" — format: "08.00"
- Column C: "Jam Pulang" — format: "16.00"
- Column D: "Kegiatan" — commit message descriptions for that day, one per line

Each row represents one working day that has at least one commit.

## Your Capabilities

You have access to the following tools exposed by the app:

### `scan_repositories(root_path: string)`
Recursively scans a folder path for Git repositories (.git directories).
Returns: list of { repo_name, repo_path, last_commit_date, total_commits }

### `get_commits(repo_paths: string[], month: int, year: int)`
Fetches all commits from the selected repositories for a given month and year.
Returns: list of {
  repo_name, repo_path,
  commit_hash, short_hash,
  author_name, author_email,
  timestamp (ISO 8601),
  message (full commit message),
  subject (first line only),
  body (rest of message, may be empty)
}

### `get_working_hours(date: string)`
Gets the stored check-in and check-out time for a specific date (ISO date format YYYY-MM-DD).
Returns: { date, check_in: "08.00", check_out: "16.00" } or null if not set

### `set_working_hours(date: string, check_in: string, check_out: string)`
Saves check-in and check-out times for a specific date.
check_in and check_out must be in format "HH.MM" (e.g. "08.00", "16.30")

### `export_excel(month: int, year: int, output_path: string)`
Triggers the Excel export for the selected month.
Returns: { success: boolean, file_path: string, row_count: int }

### `get_month_summary(month: int, year: int)`
Returns aggregate data: total commits, active days, repos contributed to, most active day.

---

## Behavior Guidelines

### Language
Always respond in the same language the user is writing in. Indonesian → Indonesian. English → English.

### Tone
Helpful, practical, concise. The user is an intern under pressure to complete a report — get to the point fast.

### When Helping with Calendar View
- Help the user understand what they see in each date cell
- Multiple commits from multiple repos on the same day = multiple cards, sorted by time
- Each commit card shows: project name (repo_name), commit description (subject), and time (HH:MM format)
- Dates with no commits are shown as empty cells

### When Helping Set Working Hours
- Default check-in: "08.00", default check-out: "17.00" unless user specifies otherwise
- If user says "jam kerja biasa" or "standar", use 08.00–17.00
- If user says "lembur sampai X", set check-out to X
- Remind user that working hours can be bulk-set for a date range if needed

### When Helping Generate the Report
- Always confirm the selected month and year before exporting
- Remind the user to check that working hours are set for all active days before exporting
- After export, tell the user the file path and how many rows were generated

### Kegiatan Column Logic
When multiple commits exist on the same day from multiple repos, combine them into the Kegiatan column like this:
  [ProjectName] Commit message one
  [ProjectName] Commit message two
  [OtherProject] Another task done

Use the commit subject (first line) only — not the full body. Keep it clean and readable.

### Working Days Rule
Only include dates that have at least one commit. Skip weekends and holidays with no commits.

---

## Example Interactions

User: "Scan folder D:/Projects"
Agent: Calls scan_repositories("D:/Projects"), then lists found repos with commit counts.

User: "Tampilkan commit bulan Januari 2026"
Agent: Calls get_commits(selected_repos, 1, 2026), presents a summary grouped by week.

User: "Set jam masuk semua hari di bulan ini jadi 08.00 dan pulang 17.00"
Agent: Calls get_month_summary to find active days, then calls set_working_hours for each active date.

User: "Export laporan Januari 2026"
Agent: Checks working hours completeness, then calls export_excel(1, 2026, default_path).

---

## Error Handling

- Repository not found or deleted: "Repo [name] tidak ditemukan. Coba scan ulang folder."
- No commits in selected month: "Tidak ada commit di bulan ini untuk repo yang dipilih."
- Working hours missing on export: "Ada [N] hari yang belum diisi jam kerja: [dates]. Isi dulu sebelum export?"
- Export failed: "Gagal membuat file Excel. Pastikan folder tujuan bisa ditulis."

---

## Security & Privacy

- All data is local — no network calls, no cloud sync
- Git repository content never leaves the device
- The agent only reads commit metadata (hash, author, time, message) — never file contents or diffs
```

---

## Arsitektur Teknis Flutter Desktop

### Tech Stack

| Komponen | Package / Solusi |
|---|---|
| Framework | Flutter 3.x (Desktop: Windows, macOS, Linux) |
| State Management | Riverpod 2.x |
| Git Integration | `dart:io` + `Process.run('git', [...])` |
| Excel Export | `excel` package (atau `syncfusion_flutter_xlsio`) |
| Folder Picker | `file_picker` |
| Local Storage | `shared_preferences` (simpan jam kerja & preferensi) |
| Calendar UI | Custom widget (tabel 7 kolom × 5-6 baris) |
| AI Agent | Anthropic Claude API via `http` package |

---

### Struktur Project Flutter

```
gittrace/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants.dart          # Warna, ukuran, format tanggal
│   │   ├── extensions.dart         # DateTime helpers, String helpers
│   │   └── theme.dart              # Flutter ThemeData
│   │
│   ├── models/
│   │   ├── repository_model.dart   # { name, path, lastCommit, totalCommits }
│   │   ├── commit_model.dart       # { hash, author, timestamp, subject, body, repoName }
│   │   ├── work_day_model.dart     # { date, checkIn, checkOut, commits[] }
│   │   └── report_row_model.dart   # { dayDate (formatted), checkIn, checkOut, kegiatan }
│   │
│   ├── services/
│   │   ├── git_scanner.dart        # Recursive .git folder search
│   │   ├── git_log_parser.dart     # Process.run git log, parse output
│   │   ├── work_hours_storage.dart # shared_preferences CRUD untuk jam kerja
│   │   ├── excel_exporter.dart     # Build dan save .xlsx file
│   │   └── claude_agent.dart       # Anthropic API client untuk AI assistant
│   │
│   ├── providers/                  # Riverpod providers
│   │   ├── folder_provider.dart    # Selected root folder path
│   │   ├── repositories_provider.dart  # Scanned repos list
│   │   ├── selected_repos_provider.dart # User-selected repos (Set<String>)
│   │   ├── commits_provider.dart   # Commits for selected month
│   │   ├── calendar_provider.dart  # Commits grouped by date (Map<DateTime, List<Commit>>)
│   │   ├── work_hours_provider.dart # Work hours per date
│   │   └── agent_provider.dart     # Chat history & agent state
│   │
│   ├── screens/
│   │   ├── home_screen.dart        # Layout utama (sidebar + main content)
│   │   ├── folder_picker_screen.dart
│   │   ├── repo_selector_screen.dart
│   │   ├── calendar_screen.dart    # Monthly calendar view utama
│   │   └── export_screen.dart      # Preview & export Excel
│   │
│   └── widgets/
│       ├── calendar/
│       │   ├── month_calendar.dart       # Grid 7×6 container
│       │   ├── calendar_day_cell.dart    # Satu kotak tanggal
│       │   ├── commit_card.dart          # Label commit di dalam sel
│       │   └── month_navigator.dart     # Tombol prev/next bulan
│       ├── repo_selector/
│       │   ├── repo_list_tile.dart
│       │   └── repo_search_bar.dart
│       ├── work_hours/
│       │   ├── time_input_field.dart     # Input jam format HH.MM
│       │   └── bulk_hour_dialog.dart     # Set jam untuk range tanggal
│       ├── export/
│       │   └── report_preview_table.dart # Preview tabel sebelum export
│       └── agent/
│           ├── agent_chat_panel.dart    # Panel AI assistant (collapsible)
│           └── agent_message_bubble.dart
│
├── windows/   # Flutter Windows runner (auto-generated)
├── macos/     # Flutter macOS runner (auto-generated)
├── linux/     # Flutter Linux runner (auto-generated)
│
└── pubspec.yaml
```

---

### pubspec.yaml (dependencies)

```yaml
name: gittrace
description: Git commit visualizer & monthly report generator for interns
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # File & folder picking
  file_picker: ^8.0.3

  # Excel export
  excel: ^4.0.2
  # Atau alternatif: syncfusion_flutter_xlsio (lebih lengkap, butuh lisensi Community)

  # Local storage (jam kerja, preferensi)
  shared_preferences: ^2.2.3

  # HTTP untuk Claude API
  http: ^1.2.1

  # Path utilities
  path: ^1.9.0
  path_provider: ^2.1.3

  # Intl (format tanggal Indonesia)
  intl: ^0.19.0

  # Window management (desktop)
  window_manager: ^0.3.9

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
```

---

### Alur Data Utama

```
1. SCAN
   User pilih folder
   → git_scanner.dart: rekursif cari semua direktori .git
   → Return List<RepositoryModel>
   → Tampil di RepoSelectorScreen sebagai checklist

2. LOAD COMMITS
   User centang repo yang diinginkan, pilih bulan/tahun
   → git_log_parser.dart: jalankan perintah:
     git log --format="%H|%an|%ae|%ai|%s|%b" --after="YYYY-MM-01" --before="YYYY-MM-31"
   → Parse output, buat List<CommitModel>
   → calendar_provider.dart: group commits by date → Map<DateTime, List<CommitModel>>
   → Render di MonthCalendar

3. SET JAM KERJA
   User klik tanggal di kalender
   → Dialog muncul: input Jam Masuk & Jam Pulang
   → work_hours_storage.dart: simpan ke shared_preferences
     Key: "work_hours_YYYY-MM-DD" → value: "08.00|17.00"

4. EXPORT EXCEL
   User klik Export
   → excel_exporter.dart:
     a. Ambil semua tanggal aktif (punya commit) di bulan itu
     b. Untuk tiap tanggal:
        - Format: "Senin, 13 Feb 2026"
        - Ambil jam masuk/pulang dari storage
        - Gabungkan semua subject commit jadi string Kegiatan
          Format: "[RepoName] commit message\n[RepoName] commit message"
     c. Tulis ke file .xlsx dengan kolom A-D
     d. Save ke folder Downloads atau lokasi pilihan user
```

---

### Format Perintah Git yang Dijalankan

```bash
# Scan: cek apakah folder adalah git repo
git -C /path/to/folder rev-parse --git-dir

# Load commits (per repo, per bulan)
git -C /path/to/repo log \
  --format="%H|%an|%ae|%ai|%s" \
  --after="2026-01-01T00:00:00" \
  --before="2026-01-31T23:59:59" \
  --no-merges

# Kalau butuh full message body
git -C /path/to/repo log \
  --format="---COMMIT---%n%H%n%an%n%ai%n%s%n%b" \
  --after="..." --before="..."
```

---

### Format Excel Output

| Kolom | Header | Format | Contoh |
|---|---|---|---|
| A | Hari, Tanggal | EEEE, d MMM yyyy (id_ID) | Senin, 13 Jan 2026 |
| B | Jam Masuk | HH.MM | 08.00 |
| C | Jam Pulang | HH.MM | 17.00 |
| D | Kegiatan | Teks bebas, newline per commit | [api-service] Fix auth bug |

Formatting Excel:
- Row 1: Header (bold, background abu-abu muda)
- Semua kolom auto-width (kecuali D = lebar tetap 400px)
- Border tipis semua sel
- Kolom D: wrap text = true, vertical align top
- Font: Calibri 11pt (default Excel)

---

### Fitur Prioritas (Urutan Development)

**Phase 1 — Core (MVP)**
- [ ] Folder picker + rekursif git scanner
- [ ] Repo selector (checklist)
- [ ] git log parser (via dart:io Process)
- [ ] Monthly calendar grid (7 kolom × 6 baris)
- [ ] Commit cards di dalam sel kalender
- [ ] Input jam masuk/pulang per tanggal (disimpan ke shared_preferences)
- [ ] Excel export

**Phase 2 — Polish**
- [ ] Bulk set jam kerja (untuk range tanggal, e.g. "set semua Senin-Jumat jadi 08.00–17.00")
- [ ] Preview tabel sebelum export
- [ ] Navigasi bulan (prev/next)
- [ ] Filter commit by author (berguna kalau repo tim)
- [ ] Dark mode

**Phase 3 — AI Agent**
- [ ] Panel chat Claude (collapsible sidebar kanan)
- [ ] Tools: scan_repositories, get_commits, set_working_hours, export_excel
- [ ] Perintah natural language: "export laporan bulan ini", "set jam kerja standar semua hari"

---

### Catatan Penting untuk Developer

1. **Git command harus dijalankan dengan working directory yang benar.**
   Selalu gunakan `git -C /path/to/repo <command>` bukan `cd` dulu.

2. **Format tanggal Indonesia.**
   Gunakan package `intl` dengan locale `id_ID`:
   ```dart
   DateFormat("EEEE, d MMM yyyy", "id_ID").format(date)
   // Output: "Senin, 13 Jan 2026"
   ```

3. **Jam kerja disimpan per tanggal, bukan per bulan.**
   Key: `"work_hours_2026-01-13"` → value: `"08.00|17.00"`
   Ini memungkinkan jam berbeda di hari berbeda (kalau ada lembur, dll).

4. **Commit dari repo yang berbeda di tanggal yang sama digabung di kolom Kegiatan.**
   Urutkan berdasarkan timestamp (paling pagi duluan).
   Format: `[nama-repo] deskripsi commit`

5. **Hanya tampilkan hari kerja dengan commit di Excel.**
   Jangan masukkan tanggal tanpa commit. Jangan masukkan akhir pekan kalau tidak ada commit.

6. **Calendar UI mirip Google Calendar.**
   - Grid 7 kolom (Senin–Minggu)
   - Nomor tanggal di pojok kiri atas tiap sel
   - Commit cards di bawah nomor tanggal, urut berdasarkan jam
   - Sel hari ini di-highlight
   - Sel di luar bulan aktif ditampilkan redup