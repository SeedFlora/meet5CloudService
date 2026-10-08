# Panduan Git Lab 05 — clone materi dan repo proyek

**Kebijakan kelas:** Lab ini latihan formatif, tanpa tugas, nilai, atau penyerahan terpisah. Satu proyek besar dikerjakan oleh kelompok **3 orang**, dengan presentasi checkpoint minggu 7 (UTS) dan hasil akhir minggu 14 (UAS). Git boleh dipakai untuk referensi pribadi atau proses proyek. Baca [brief proyek kelompok](PROYEK_KELOMPOK.md); bobot resmi mengikuti RPS/LMS.

## 1. Pilih tujuan sebelum clone

| Tujuan | Repo yang di-clone | Push |
|---|---|---|
| Mengikuti demo kelas di PC kampus | [SeedFlora/meet5CloudService](https://github.com/SeedFlora/meet5CloudService) | Percobaan dapat tetap lokal. Jangan push ke repo pengajar. |
| Menyimpan percobaan pribadi atau melanjutkan proyek kelompok 3 orang | Repo hasil template/fork dengan owner akun Anda/kelompok | Opsional, ke origin milik Anda yang telah diperiksa. |

`git clone` membuat folder kerja, metadata `.git`, dan remote `origin`. Repo hasil clone **tidak memerlukan `git init`**. Clone kode tidak mengunduh Docker image atau isi database; build/runtime disiapkan melalui modul.

## 2. Clone materi publik dari PC kampus

Gunakan PowerShell pada akun Anda. [Modul PC kampus](MODUL_MAHASISWA.md#mulai-dari-komputer-kampus-windows) menjelaskan pemeriksaan Git/Docker Desktop dan folder yang dapat ditulis. Untuk clone pertama:

```powershell
git --version
$campusFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CloudServices'
New-Item -ItemType Directory -Path $campusFolder -Force | Out-Null
Set-Location -LiteralPath $campusFolder
git clone https://github.com/SeedFlora/meet5CloudService.git
Set-Location -LiteralPath 'meet5CloudService'
Get-ChildItem -LiteralPath 'Dockerfile', 'requirements.txt', 'app/main.py'
git remote -v
git status --short
```

**Baca hasil:** tiga berkas ditemukan, remote origin adalah URL pengajar, dan clone baru bersih. Terminal kini di root repo. Lanjutkan [build dan uji API](MODUL_MAHASISWA.md#persiapan-dan-build). Clone/build pertama membutuhkan internet. Jika folder sudah ada, gunakan bagian 4; jangan clone di atas folder berisi pekerjaan lama.

![Menu HTTPS GitHub untuk mengambil URL clone materi publik](screenshots/campus/01_clone_https.jpg)

**Command / langkah:** `Code > Local > HTTPS` dan `git clone https://github.com/SeedFlora/meet5CloudService.git`. **Fungsi/cara kerja:** ambil URL sumber dari GitHub lalu salin kode/riwayat ke repo lokal; clone membuat .git dan origin. **Baca:** screenshot aktual menunjukkan menu HTTPS repo pengajar, dengan URL lengkap pada command agar dapat disalin. Ini screenshot GitHub, bukan PowerShell kampus; periksa file/remote setelah menjalankan blok clone pada PC Anda.

## 3. Repo pribadi atau kelompok — opsional

Jika ingin push kontribusi, buat repo milik Anda dahulu di GitHub. Pada halaman materi, pilih **Use this template → Create a new repository**; tentukan owner Anda/kelompok dan nama repo. Jika tombol tidak tersedia pada repo lain, **Fork** ke akun Anda dapat digunakan. Satu kelompok tetap mengembangkan satu proyek bersama; tidak perlu membuat penyerahan/repo wajib setiap lab. [Template GitHub](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

Pada repo baru, pilih **Code → Local → HTTPS** dan salin URL milik Anda. Dari folder CloudServices di PowerShell:

```powershell
$campusFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CloudServices'
New-Item -ItemType Directory -Path $campusFolder -Force | Out-Null
Set-Location -LiteralPath $campusFolder
$projectRepoUrl = Read-Host 'Tempel URL HTTPS repo milik Anda/kelompok dari Code > HTTPS'
git clone $projectRepoUrl cloud-notes-project
Set-Location -LiteralPath 'cloud-notes-project'
git remote -v
Get-ChildItem -LiteralPath 'Dockerfile', 'requirements.txt', 'app/main.py'
```

**Checkpoint:** origin menunjukkan owner/repo kelompok Anda, tiga berkas materi tersedia, terminal pada root repo tersebut. Folder `cloud-notes-project` harus belum ada untuk clone pertama; jika sudah ada, masuk folder itu dan ikuti bagian 4. URL berasal dari repo template/fork milik Anda. Tidak perlu `git init` atau origin kedua. Bagikan akses kolaborasi repo kelompok melalui GitHub sesuai pilihan owner. Codespaces juga dapat dibuka dari **Code → Codespaces** pada repo sendiri.

## 4. Memperbarui repo yang sudah ada

Dari root repo yang benar:

```bash
git remote -v
git status --short
```

Jika output status kosong, jalankan:

```bash
git pull --ff-only
```

Ini mengambil pembaruan dari remote/branch yang dilacak dan hanya menerapkan fast-forward. Bila ada perubahan lokal atau history berbeda, tinjau dahulu; jangan overwrite, reset paksa, atau menghapus folder untuk memaksa pull. Template adalah salinan mandiri: pull dari origin pribadi mengikuti repo pribadi, tidak otomatis mengikuti revisi repo pengajar. Perbarui materi pengajar di clone materi terpisah, lalu tinjau perubahan yang ingin diterapkan pada proyek Anda.

## 5. Commit dan push hanya pada repo milik Anda

Ini opsional, sesudah perubahan yang ingin disimpan dibuat. Periksa `git remote -v` dan pastikan origin milik Anda. Pada PC kampus, bila Git meminta identitas commit, gunakan konfigurasi lokal repo:

```powershell
$commitName = Read-Host 'Nama penulis commit Anda'
$commitEmail = Read-Host 'Email commit Anda, boleh email noreply GitHub'
git config --local user.name $commitName
git config --local user.email $commitEmail
```

Identitas commit berbeda dari autentikasi push. Push menggunakan akun yang memiliki akses melalui mekanisme login Git/GitHub; jangan menaruh password atau token di command/modul/screenshot.

Dari root repo pribadi, stage hanya file yang memang berubah:

```bash
git status --short
git diff --check
git add -- app/main.py Dockerfile .dockerignore requirements.txt
git diff --cached --name-only
git diff --cached --check
git diff --cached
```

Pastikan staged berisi perubahan yang dimaksud, tanpa `.env`, kredensial, private key, isi database, atau panduan dosen privat. Jika benar dan ada perubahan:

```bash
git commit -m "lab05: update dan uji Cloud Notes API"
git push
```

Jika `nothing to commit`, tidak perlu commit kosong. Repo template/fork yang di-clone umumnya melacak branch remote; ikuti pesan Git bila branch baru belum memiliki upstream. Catatan `hasil/lab05.md` dan bukti `hasil/bukti/` hanya opsional jika dibuat; stage secara sadar bila ingin disimpan. Gambar pada `screenshots/` adalah referensi materi, bukan bukti pribadi atau tugas wajib.

Rujukan: [clone HTTPS GitHub](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository), [Git clone](https://git-scm.com/docs/git-clone), [Git pull](https://git-scm.com/docs/git-pull), [GitHub template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template), serta [instalasi Compose](https://docs.docker.com/compose/install/) untuk persiapan runtime.
