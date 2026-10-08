# Lab 05 — Dockerfile untuk Cloud Notes API

<!-- lecture-materials:start -->

## Materi teori sebelum praktikum

- [Pertemuan 05: Docker Core](slides/Teori_Pertemuan_05.pptx)
- [Kode contoh teori Node.js 24: satu stage dan multi-stage](examples/theory-node/README.md)
- [Demo Docker penuh di browser, dengan screenshot setiap tahap](DEMO_ONLINE.md)
- [PDF panduan demo online](DEMO_ONLINE.pdf)
- [Kredit foto dan sumber perumpamaan pada PPT](slides/SUMBER_GAMBAR.md)

Slide menghubungkan konsep, kasus kerja, bacaan/video resmi, dan langkah lab. Revisi 8 Oktober 2026 menambahkan perumpamaan restoran dengan foto berlisensi serta 14 screenshot alur demo Codespaces. Contoh FastAPI telah dibangun dan diuji end to end di Codespaces melalui Chrome; kedua contoh Node.js telah dibangun dan diuji lokal.

<!-- lecture-materials:end -->

**Kebijakan kelas:** Lab ini latihan formatif, tanpa tugas, nilai, atau penyerahan terpisah. Satu proyek besar dikerjakan oleh kelompok **3 orang**, dengan presentasi checkpoint minggu 7 (UTS) dan hasil akhir minggu 14 (UAS). Simpan hasil lab hanya bila berguna sebagai referensi atau bukti proses proyek. Baca [brief proyek kelompok](PROYEK_KELOMPOK.md). Bobot resmi tetap mengikuti RPS/LMS.

Repo template: [SeedFlora/meet5CloudService](https://github.com/SeedFlora/meet5CloudService). [Modul mahasiswa](MODUL_MAHASISWA.md) memuat screenshot, jawaban analisis, dan kunci lengkap tantangan `/stats`; [panduan Git](PANDUAN_GIT.md) dipakai dari root repo pribadi. Versi cetak: [PDF mahasiswa](MODUL_MAHASISWA.pdf). Slide kelas ada di `slides/`.

**Capaian:** menulis Dockerfile multi-stage, mengecilkan build context dengan `.dockerignore`, memberi tag image, menjalankan image dengan environment variable, dan menguji REST API. Data lab ini sementara tersimpan di memori; Lab 06 menambahkan database.

## Demo teori tanpa instalasi di laptop

Buka repo ini, lalu **Code → Codespaces → Create codespace on main**. Gunakan mesin **2 core** dan tunggu terminal Linux siap. Docker dipasang di mesin cloud oleh konfigurasi repo; laptop hanya memerlukan browser, akun GitHub, internet, dan kuota Codespaces.

Jalankan command satu per satu:

```bash
bash scripts/demo-online.sh check
bash scripts/demo-online.sh build
bash scripts/demo-online.sh start
bash scripts/demo-online.sh status
bash scripts/demo-online.sh test
```

Buka tab **Ports**, pilih **8000**, pertahankan **Private**, lalu **Open in Browser** dan tambahkan `/docs`. Swagger menyediakan tombol **Try it out → Execute** untuk GET `/health`, POST `/notes`, dan GET `/notes`. `localhost` pada terminal menunjuk mesin cloud; browser laptop memakai URL forwarded dari Ports.

Setelah demo:

```bash
bash scripts/demo-online.sh test --restart
bash scripts/demo-online.sh stop
```

Restart mengosongkan catatan memori pada contoh ini. Selanjutnya buka [Codespaces](https://github.com/codespaces), pilih menu **… → Stop codespace** pada lingkungan kelas. Compute berhenti; storage tetap dihitung selama lingkungan disimpan. Kuota gratis terbatas. [Panduan bergambar](DEMO_ONLINE.md) menjelaskan arti setiap command, hasil aktual, troubleshooting, serta jalur cadangan Killercoda.

## Jalankan secara lokal

Dari root repo Lab 05:

```bash
docker build -t cloud-notes-api:lab05 .
docker image ls cloud-notes-api
docker run --name cloudlab-api -d -p 127.0.0.1:8000:8000 -e APP_ENV=classroom cloud-notes-api:lab05
docker logs cloudlab-api
```

Buka `http://127.0.0.1:8000/docs` untuk mencoba OpenAPI. Uji lewat PowerShell:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/runtime
Invoke-RestMethod http://127.0.0.1:8000/notes -Method Post -ContentType application/json -Body '{"title":"Docker","content":"Image adalah template; container adalah proses."}'
Invoke-RestMethod http://127.0.0.1:8000/notes
```

Atau bash:

```bash
curl -fsS http://127.0.0.1:8000/health
curl -fsS -X POST http://127.0.0.1:8000/notes -H 'Content-Type: application/json' -d '{"title":"Docker","content":"Image adalah template; container adalah proses."}'
curl -fsS http://127.0.0.1:8000/notes
```

Uji validasi dengan judul kosong: API seharusnya mengembalikan HTTP 422. Lalu hentikan/hapus container dan jalankan ulang; catatan akan hilang karena masih berada di memori.

```bash
docker rm -f cloudlab-api
```

## Hal yang diamati

- `COPY` dipakai untuk berkas lokal; `ADD` punya kemampuan ekstra seperti ekstraksi arsip yang tidak diperlukan di sini.
- Tahap `builder` memasang dependency ke virtual environment; tahap `runtime` hanya membawa dependency dan kode.
- `USER appuser` mencegah proses aplikasi berjalan sebagai root.
- Tag `lab05` memberi versi yang dapat disebut jelas saat demo.

**Git opsional:** commit kode dan Dockerfile. Untuk push ke Docker Hub, buat akun dan jalankan `docker tag cloud-notes-api:lab05 NAMA_AKUN/cloud-notes-api:lab05`, `docker login`, `docker push NAMA_AKUN/cloud-notes-api:lab05`. Simpan kode di GitHub; push image ke registry hanya bila dipakai untuk menjalankan proyek.

Rujukan: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/), [multi-stage builds](https://docs.docker.com/build/building/multi-stage/).

## Bukti pengujian kelas 8 Oktober 2026

FastAPI berhasil dibangun dan diuji: `/health`, `/runtime`, dan `/docs` 200; POST `/notes` 201; input kosong 422; ID tidak ditemukan 404. Proses memakai UID 10001. Sesudah `docker restart`, catatan memori kosong kembali. Kedua contoh Node.js juga berhasil dibangun dan diuji; contoh multi-stage memakai UID 1000.

Screenshot berikut diambil langsung dari Swagger di Chrome. Uji ini memakai port host **18005** untuk menghindari benturan; port container tetap **8000**. Langkah utama modul memakai host **8000**. Di `/docs`, buka GET `/health`, klik **Try it out**, lalu **Execute**.

![Swagger menampilkan command curl dan respons HTTP 200](screenshots/teori05_swagger_health_detail_20261008.jpg)

Perintah yang setara pada Bash: `curl -i http://127.0.0.1:18005/health`; pada Windows: `curl.exe -i http://127.0.0.1:18005/health`. `-i` menampilkan header dan body. HTTP 200 dengan `status: ok` menunjukkan endpoint API dapat diakses; ini belum memeriksa database. Uji membutuhkan container berjalan pada mapping port tersebut.
