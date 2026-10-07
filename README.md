# Lab 05 — Dockerfile untuk Cloud Notes API

Repo template: [SeedFlora/meet5CloudService](https://github.com/SeedFlora/meet5CloudService). [Modul mahasiswa](MODUL_MAHASISWA.md) memuat screenshot, jawaban analisis, dan kunci lengkap tantangan `/stats`; [panduan dosen](PANDUAN_DOSEN.md) memberi alur demo 90 menit; [panduan Git](PANDUAN_GIT.md) dipakai dari root repo pribadi. Versi cetak: [PDF mahasiswa](MODUL_MAHASISWA.pdf) dan [PDF dosen](PANDUAN_DOSEN.pdf). Slide kelas ada di `slides/`.

**Capaian:** menulis Dockerfile multi-stage, mengecilkan build context dengan `.dockerignore`, memberi tag image, menjalankan image dengan environment variable, dan menguji REST API. Data lab ini sementara tersimpan di memori; Lab 06 menambahkan database.

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

**Git opsional:** commit kode dan Dockerfile. Untuk push ke Docker Hub, buat akun dan jalankan `docker tag cloud-notes-api:lab05 NAMA_AKUN/cloud-notes-api:lab05`, `docker login`, `docker push NAMA_AKUN/cloud-notes-api:lab05`. Jangan push image ke registry bila hanya perlu GitHub untuk penilaian.

Rujukan: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/), [multi-stage builds](https://docs.docker.com/build/building/multi-stage/).
