# Lab 05 - Docker Core di Windows PowerShell

Praktik ini dijalankan pada **Docker Desktop di PC Windows**, melalui **PowerShell**. Gunakan [modul mahasiswa langkah demi langkah](MODUL_MAHASISWA.md) sebagai urutan kelas. [Versi PDF modul](MODUL_MAHASISWA.pdf) mempunyai isi yang sama; slide lama bukan petunjuk menjalankan praktik lokal yang baru ini.

**Kebijakan kelas:** latihan formatif, tanpa tugas, nilai, atau pengumpulan individu/per lab. Proyek besar tetap kelompok **3 orang**, dengan checkpoint presentasi minggu **7 (UTS)** dan hasil akhir minggu **14 (UAS)**. Bukti praktik boleh disimpan sebagai referensi proyek. Ketentuan penilaian resmi mengikuti RPS/LMS dan [brief proyek kelompok](PROYEK_KELOMPOK.md).

## Urutan sesuai RPS Lab 05

1. Menulis Dockerfile pertama untuk aplikasi Python: [Dockerfile.single](Dockerfile.single).
2. Build image dengan nama dan tag.
3. Mempelajari builder/runtime pada [Dockerfile](Dockerfile), lalu membandingkan hasil build.
4. Menjalankan image sendiri dengan environment variable dan port mapping.
5. Membaca [.dockerignore](.dockerignore), kemudian login, tag, dan push ke Docker Hub milik sendiri dari PC lokal. Bagian Docker Hub ada di akhir modul; pada sesi gabungan 100 menit, pelaksanaannya berada di luar alur utama tersebut.

Python tidak perlu dipasang di Windows. Runtime dan dependency aplikasi berada dalam image. Source aplikasi [app/main.py](app/main.py) adalah Cloud Notes versi **0.5** dengan penyimpanan memori.

## Mulai dari satu folder lokal

Buka Docker Desktop dan tunggu Engine siap. Buka PowerShell pada folder belajar yang dapat ditulis, lalu jalankan satu per satu:

```powershell
git --version
docker version
docker info --format '{{.OSType}}'
git clone https://github.com/SeedFlora/meet5CloudService.git
Set-Location .\meet5CloudService
Get-Location
Get-ChildItem Dockerfile.single, Dockerfile, requirements.txt, app
```

`docker version` harus menampilkan **Client dan Server**; jenis OS harus **linux**. Sesudah clone, seluruh command berikut dijalankan dari folder **meet5CloudService** yang langsung berisi Dockerfile dan `app/`. Clone hanya dijalankan sekali. Untuk repo yang sudah tersedia, buka folder itu di Explorer/VS Code dan buka PowerShell di sana.

## Build dan jalankan

Baca bagian menulis Dockerfile pada modul, kemudian:

```powershell
docker build -f Dockerfile.single -t cloud-notes-api:single05 .
docker build -t cloud-notes-api:lab05 .
docker image ls cloud-notes-api
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
```

Sebelum `run`, pastikan nama `cloudlab-core05` dan host port **18005** belum dipakai. Hentikan proses lain hanya setelah mengetahui pemiliknya; panduan tidak menjalankan cleanup otomatis.

```powershell
docker run --name cloudlab-core05 -d -p 127.0.0.1:18005:8000 -e APP_ENV=classroom cloud-notes-api:lab05
docker ps --filter name=cloudlab-core05
docker logs --tail 15 cloudlab-core05
```

**Tunggu log `Application startup complete.`** sebelum melanjutkan. Jalankan kembali command logs di atas untuk membaca perkembangan startup. Setelah Uvicorn siap:

```powershell
curl.exe -i http://127.0.0.1:18005/health
curl.exe -i http://127.0.0.1:18005/runtime
```

Buka **http://127.0.0.1:18005/docs** di Chrome. Hasil: API **0.5**, health HTTP **200** dengan `service=cloud-notes-api`, serta runtime `environment=classroom`, `storage=memory`. Host **18005** diteruskan ke port **8000** dalam container. Data ini belum memakai database.

Modul menjelaskan setiap instruksi Dockerfile, build context, `RUN` versus `CMD`/`ENTRYPOINT`, user runtime, penggunaan Swagger, `.dockerignore`, serta langkah Docker Hub. Gambar lama yang dipakai diberi caption nama/port asal; command praktik tetap mengikuti modul lokal ini.

## Setelah selesai

Untuk menutup **container yang Anda buat di atas**, jalankan secara manual:

```powershell
docker stop cloudlab-core05
docker rm cloudlab-core05
```

Image tetap tersedia. Catatan yang hanya berada di memori proses tidak dipertahankan. Lanjutkan topik multi-container menggunakan [modul lokal Lab 06](https://github.com/SeedFlora/meet6CloudService/blob/main/MODUL_MAHASISWA.md).
