# Modul mahasiswa Lab 05 — Dockerfile dan Cloud Notes API

**Sesi RPS:** 05 · **Jalur utama:** build dan run lokal · **Lanjutkan ke:** repo Lab 06 setelah praktik ini

## Hasil belajar

Anda dapat menjelaskan tiap tahap [`Dockerfile`](Dockerfile), membangun image bertag, menguji REST API dalam container, menunjukkan proses berjalan sebagai user non-root, dan menjelaskan mengapa catatan hilang setelah container diganti. Kode FastAPI ada di [`app/main.py`](app/main.py); dependensi ada di [`requirements.txt`](requirements.txt).

**Teori singkat.** Dockerfile adalah resep build image. Tahap `builder` memasang dependensi Python ke virtual environment; tahap `runtime` menyalin hanya hasil yang diperlukan serta kode aplikasi. [`.dockerignore`](.dockerignore) mengurangi berkas yang masuk ke build context. `RUN` dieksekusi saat build; `CMD` memberi perintah default saat container mulai, sedangkan `ENTRYPOINT` dapat menetapkan executable utama. `ENV` pada Dockerfile berbeda dari `-e` pada `docker run`: `-e` memasok nilai saat container dijalankan. Data API ini disimpan di memori proses, belum di volume/database.

## Persiapan dan build

Pastikan Docker Engine berjalan, port host **8000** kosong, dan terminal berada di root repo Lab 05. Di PowerShell, Bash, atau WSL:

```bash
docker version
docker build -t cloud-notes-api:lab05 .
docker image ls cloud-notes-api
docker run --name cloudlab-api -d -p 127.0.0.1:8000:8000 -e APP_ENV=classroom cloud-notes-api:lab05
docker ps --filter name=cloudlab-api
docker logs cloudlab-api
docker exec cloudlab-api id
docker image inspect cloud-notes-api:lab05 --format '{{.Size}} bytes; user={{.Config.User}}'
```

**Checkpoint A:** image `cloud-notes-api:lab05` terdaftar; log menunjukkan Uvicorn menerima koneksi pada port 8000. Tunggu beberapa detik bila API belum siap segera setelah `docker run`. Buka `http://127.0.0.1:8000/docs`. Dokumentasi OpenAPI yang Anda lihat akan mirip screenshot hasil run lokal berikut.

![Tag image, user runtime non-root, dan pemetaan port dari Docker](screenshots/lab05_build.png)

* **Langkah:** Jalankan `docker build -t cloud-notes-api:lab05 .`, `docker exec cloudlab-api id`, dan `docker image inspect`. **Fungsi:** Membuktikan build API, user runtime non-root, serta port yang dipakai. **Cara kerja:** Dockerfile multi-stage membuat image; proses API berjalan sebagai appuser di dalam container. **Baca hasil:** Baca tag image, UID 10001/appuser, dan mapping host 8000 ke container 8000; ukuran image dapat berbeda.

*Gambar: hasil aktual `docker image inspect`, `docker exec id`, dan `docker ps`. Pada mesin Anda, periksa `appuser`, UID 10001, dan port host 8000; ukuran image dapat berbeda.*

![Docker Desktop menampilkan container API Lab 05 yang berjalan](screenshots/00_docker_desktop.jpg)

* **Langkah:** Buka Docker Desktop > Containers setelah `docker run`, lalu bandingkan dengan `docker ps`. **Fungsi:** Melihat status container dan pemetaan port tanpa kehilangan arti perintah CLI. **Cara kerja:** Docker menjalankan image `cloud-notes-api:lab05` sebagai container; titik hijau menandai proses sedang berjalan. **Baca hasil:** Pada screenshot uji, host **8005** diteruskan ke port container **8000** (`docker run --name cloudlab-api-visual -d -p 127.0.0.1:8005:8000 ...`) karena Lab 06 memakai host 8000 pada waktu yang sama. Langkah utama Anda tetap memakai `127.0.0.1:8000:8000` dan URL port 8000; status HTTP 200 diuji terpisah agar titik hijau tidak disalahartikan sebagai healthcheck.*

![OpenAPI Cloud Notes dari image Lab 05 yang berjalan](screenshots/lab05_openapi.png)

* **Langkah:** Setelah `docker run -p 127.0.0.1:8000:8000`, buka `http://127.0.0.1:8000/docs`. **Fungsi:** Mengenali kontrak endpoint API Cloud Notes. **Cara kerja:** FastAPI membangun Swagger UI dari skema OpenAPI aplikasi yang hidup di container. **Baca hasil:** Cari route `/health`, `/runtime`, dan `/notes`; buka satu route untuk melihat metode serta bentuk respons.

## Praktik API dan validasi

Di PowerShell:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/runtime
Invoke-RestMethod http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"Docker","content":"Catatan kelas"}'
Invoke-RestMethod http://127.0.0.1:8000/notes
try { Invoke-WebRequest http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"","content":"uji"}' -UseBasicParsing } catch { [int]$_.Exception.Response.StatusCode }
```

Di Bash/WSL:

```bash
curl -fsS http://127.0.0.1:8000/health
curl -fsS http://127.0.0.1:8000/runtime
curl -fsS -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"Docker","content":"Catatan kelas"}'
curl -fsS http://127.0.0.1:8000/notes
curl -s -o /dev/null -w '%{http_code}\n' -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"","content":"uji"}'
```

**Checkpoint B:** `/health` bernilai `ok`, `/runtime` menampilkan `APP_ENV=classroom` dan `storage=memory`, POST membuat catatan, GET menampilkannya, dan judul kosong menghasilkan HTTP **422**. ID dan urutan catatan bisa berbeda. Screenshot berikut adalah contoh respons dari container lokal; buat bukti sendiri saat praktik.

![Respons aktual health, runtime, POST, dan GET Lab 05](screenshots/lab05_api.png)

* **Langkah:** Kirim GET `/health`, GET `/runtime`, POST `/notes`, dan GET `/notes` dengan `curl` atau `Invoke-RestMethod`. **Fungsi:** Menguji kesehatan, identitas runtime, dan alur tulis/baca catatan. **Cara kerja:** Request host masuk melalui port publish ke FastAPI; POST menyimpan catatan dalam memori proses. **Baca hasil:** Baca `status` sehat, `appuser`, respons catatan baru, lalu item yang sama pada daftar GET.

Hapus container, jalankan image yang sama lagi, lalu GET daftar catatan. Gunakan perintah sesuai terminal:

```bash
docker rm -f cloudlab-api
docker run --name cloudlab-api -d -p 127.0.0.1:8000:8000 -e APP_ENV=classroom cloud-notes-api:lab05
```

PowerShell: `Invoke-RestMethod http://127.0.0.1:8000/notes`; Bash: `curl -fsS http://127.0.0.1:8000/notes`. **Checkpoint C:** daftar dimulai kosong setelah proses/container baru siap. Jelaskan penyebabnya dan bandingkan dengan Lab 06 nanti.

![HTTP 422 untuk input kosong dan daftar kosong sesudah container dibuat ulang](screenshots/lab05_validation_reset.png)

* **Langkah:** POST judul kosong ke `/notes`, lalu `docker rm -f cloudlab-api` dan jalankan container baru dari image sama. **Fungsi:** Mendemonstrasikan validasi input dan batas penyimpanan in-memory. **Cara kerja:** FastAPI menolak payload tidak valid; container baru memulai proses dengan memori kosong. **Baca hasil:** Cari HTTP 422 dan daftar catatan kosong setelah restart lewat container baru.

*Gambar: output aktual dari POST valid, POST berjudul kosong, dan GET setelah `docker rm`/`docker run`. ID serta isi catatan Anda boleh berbeda.*

**Tantangan kode mandiri:** tambahkan endpoint `GET /stats` pada salinan Anda di `app/main.py`. Kembalikan `note_count` dan `longest_title_chars`; saat belum ada catatan keduanya bernilai 0. Gunakan lock yang sama dengan operasi catatan, uji sebelum dan sesudah membuat dua catatan, lalu build ulang image dengan tag berbeda. Tantangan ini latihan tambahan; endpoint inti di atas harus berhasil lebih dahulu.

## Analisis, laporan, dan Git

Jawab tanpa menyalin contoh: (1) bagian mana dari Dockerfile berjalan saat build dan bagian mana saat run; apa beda `CMD` dan `ENTRYPOINT` dalam konteks ini; (2) mengapa `.dockerignore` memuat `.env`; (3) apa arti port kiri/kanan pada `127.0.0.1:8000:8000`; (4) apa hubungan validasi `Field(min_length=1)` dengan HTTP 422; (5) apa kelemahan menyimpan catatan hanya di memori.

Dari root repo, salin [template laporan](hasil/TEMPLATE_LAPORAN.md) menjadi `hasil/lab05.md`: PowerShell `Copy-Item hasil/TEMPLATE_LAPORAN.md hasil/lab05.md`; Bash `cp hasil/TEMPLATE_LAPORAN.md hasil/lab05.md`. Isi hasil nyata, perintah, jawaban, dan screenshot Anda di `hasil/bukti/`. Jangan memakai screenshot modul sebagai bukti pribadi.

```bash
docker rm -f cloudlab-api
```

Dari root repo Lab 05, ikuti [panduan Git](PANDUAN_GIT.md) untuk repo sendiri:

```bash
git status --short
git add Dockerfile .dockerignore requirements.txt app MODUL_MAHASISWA.md hasil/lab05.md hasil/bukti
git diff --cached --name-only
git diff --cached --check
git commit -m "lab05: build dan uji Cloud Notes API"
git push
```

Jika belum ada folder bukti, hilangkan argumen itu dari `git add`. Pastikan staged tidak berisi `.env`, kredensial, atau hasil build. Jika push pertama belum punya upstream, jalankan `git push -u origin main`.

**Jika gagal:** konflik port 8000 biasanya berarti container Lab 06 atau Lab 05 lama masih aktif (`docker ps`). Jika `docker build` gagal mengambil image/dependensi, cek koneksi internet dan jalankan ulang. Jika aplikasi belum siap setelah `run`, tunggu status log Uvicorn sebelum memanggil API.

**Pilihan cloud — Docker Hub:** bila dosen meminta publish image dan Anda punya akun, jalankan `docker tag cloud-notes-api:lab05 NAMA_AKUN/cloud-notes-api:lab05`, `docker login`, lalu `docker push NAMA_AKUN/cloud-notes-api:lab05`. Ganti `NAMA_AKUN`; jangan merekam token login atau memasukkannya ke repo. Push Git untuk kode tetap terpisah dari push image ke registry.

## Kunci tantangan dan kasus kerja harian

**Kasus:** tim support perlu melihat jumlah tiket/catatan serta judul terpanjang tanpa membuka semua isi catatan. Anda menambahkan endpoint statistik baca saja. Kunci ada di bawah; lakukan percobaan sendiri dahulu, lalu bandingkan hasil. Semua perintah dijalankan dari **root repo Lab 05**.

### 1. Baca kontrak aplikasi

`Dockerfile` tahap `builder` memasang paket ke `/opt/venv`; tahap `runtime` menyalin hasilnya, memasang kode, dan menjalankan Uvicorn sebagai UID 10001. `docker build` menjalankan instruksi build dan menghasilkan image. `docker run` membuat proses container dari image tersebut. Port kiri `127.0.0.1:8000` adalah port laptop yang hanya menerima koneksi lokal; port kanan `8000` milik proses dalam container.

### 2. Kunci kode `GET /stats`

Tambahkan potongan berikut ke akhir `app/main.py`, di luar fungsi lain. Variabel `_notes` dan `_lock` sudah disediakan oleh starter; jangan membuat dictionary atau lock baru karena hasilnya akan terpisah dari endpoint `/notes`.

```python
@app.get("/stats")
def stats() -> dict[str, int]:
    with _lock:
        titles = [item["title"] for item in _notes.values()]
        return {
            "note_count": len(titles),
            "longest_title_chars": max((len(title) for title in titles), default=0),
        }
```

Lock memastikan snapshot daftar judul konsisten bila ada request POST bersamaan. `default=0` membuat hasil awal tetap valid ketika belum ada catatan. Hitung panjang judul yang sudah divalidasi dan dipangkas spasinya oleh `NoteInput`.

### 3. Build ulang dan uji dari awal sampai akhir

Gunakan tag baru supaya jelas image mana yang berisi solusi. Hapus container percobaan Lab 05 yang lama bila masih ada, lalu:

```bash
docker build -t cloud-notes-api:stats .
docker rm -f cloudlab-api
docker run --name cloudlab-api -d -p 127.0.0.1:8000:8000 -e APP_ENV=classroom cloud-notes-api:stats
```

Jika `docker rm` melaporkan container tidak ada, lanjutkan ke `docker run`. Tunggu `/health` menjawab HTTP 200. Di **PowerShell**, jalankan:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/stats
Invoke-RestMethod http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"Ops","content":"Pertama"}'
Invoke-RestMethod http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"Incident 42","content":"Kedua"}'
Invoke-RestMethod http://127.0.0.1:8000/stats
try { Invoke-WebRequest http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"   ","content":"uji"}' -UseBasicParsing } catch { [int]$_.Exception.Response.StatusCode }
```

Di **Bash/Git Bash**, padanannya:

```bash
curl -fsS http://127.0.0.1:8000/stats
curl -fsS -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"Ops","content":"Pertama"}'
curl -fsS -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"Incident 42","content":"Kedua"}'
curl -fsS http://127.0.0.1:8000/stats
curl -s -o /dev/null -w '%{http_code}\n' -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"   ","content":"uji"}'
```

**Hasil kunci:** awal `{"note_count":0,"longest_title_chars":0}`; sesudah dua POST `{"note_count":2,"longest_title_chars":11}`; judul spasi saja ditolak HTTP **422**. Jika hasil `/stats` masih 404, image baru belum dibuild atau container masih memakai tag lama. Cek dengan `docker ps --filter name=cloudlab-api --format '{{.Image}}'`. Setelah merekam bukti, jalankan `docker rm -f cloudlab-api`.

![Bukti build dan respons API Lab 05 yang dijalankan kembali](screenshots/lab05_uji_terkini.png)

*Perintah: `docker build`, `docker run`, GET health/runtime, POST dan GET notes, lalu uji judul spasi. Cuplikan hasil Docker dan HTTP aktual ditata agar terbaca. HTTP 201 berarti catatan dibuat; HTTP 422 menunjukkan validasi; container baru mengembalikan daftar kosong karena data hanya di memori.*

![Dokumentasi OpenAPI dari container Lab 05 yang berjalan](screenshots/lab05_docs_live_terkini.png)

*Perintah: buka `http://127.0.0.1:8000/docs` setelah `docker run`. Browser mengambil Swagger UI dari API yang sedang hidup. Gunakan route `/health`, `/runtime`, dan `/notes` untuk membaca kontrak sebelum memanggil endpoint.*

![Tantangan stats yang diuji pada image solusi sementara](screenshots/lab05_stats_kunci_teruji.png)

*Perintah: tambah kode `/stats` di salinan uji, build image `stats-proof`, lalu GET sebelum/sesudah dua POST. Gambar adalah hasil API aktual yang ditata agar terbaca: jumlah 0→2, judul terpanjang 11 karakter, dan input kosong HTTP 422. Starter repo tetap menyisakan tantangan untuk dikerjakan sendiri.*

### 4. Kunci lima pertanyaan analisis

1. `RUN` dan `COPY` mengubah image saat build; `CMD` dijalankan saat container start. `ENTRYPOINT` dapat menetapkan executable utama yang menerima argumen dari `CMD`; lab ini cukup dengan `CMD` Uvicorn.
2. `.dockerignore` mencegah `.env` masuk build context sehingga konfigurasi lokal tidak ikut image. File rahasia tetap harus diabaikan Git.
3. Pada `127.0.0.1:8000:8000`, bagian kiri adalah alamat dan port laptop; bagian kanan adalah port aplikasi dalam container. Loopback membatasi akses dari host lain.
4. `Field(min_length=1)` menolak string kosong. Validator tambahan `reject_blank_text` memangkas spasi dan menolak teks yang hanya berisi spasi; FastAPI memberi 422 karena payload gagal validasi.
5. `_notes` hidup di memori proses. Mengganti container membuat memori baru dan daftar kosong. Lab 06 memindahkan sumber data ke PostgreSQL dalam named volume.
