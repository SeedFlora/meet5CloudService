# Contoh teori minggu 5: Docker Core dengan Node.js 24

Contoh kecil ini menghubungkan teori Dockerfile dengan layanan web yang bisa diuji. Gunakan sebagai demonstrasi atau latihan bersama sebelum Lab 05 FastAPI. Latihan ini formatif, tanpa tugas atau nilai terpisah. Proyek kelompok tetap mengikuti panduan proyek utama.

## Persiapan

Jalankan Docker Desktop atau Docker Engine. Buka terminal dari akar repository, lalu pindah ke folder contoh:

```sh
cd examples/theory-node
docker version
```

Pastikan bagian `Server` muncul. Node.js dan npm di laptop tidak diperlukan karena proses instalasi dan build berlangsung di image Node.js. `server.js` memakai `node:http` bawaan, sehingga tidak memerlukan paket eksternal. `package-lock.json` tetap disertakan agar `npm ci` dapat dijalankan.

## 1. Image sederhana: satu stage

```sh
docker build -t lab05-theory-node:simple .
docker run -d --name lab05-theory-node-simple -p 127.0.0.1:13005:3000 lab05-theory-node:simple
docker logs lab05-theory-node-simple
```

- `build` membaca `Dockerfile` dan konteks folder ini; `-t` memberi tag image.
- `FROM` memilih image Node.js 24 Alpine. `WORKDIR` menetapkan direktori kerja.
- `COPY package.json package-lock.json ./` menyalin metadata lebih dahulu sehingga perubahan source tidak selalu membatalkan cache instalasi.
- `RUN npm ci --omit=dev` mengikuti lockfile dan mengabaikan dependency pengembangan. Contoh ini tidak memiliki dependency eksternal.
- `COPY . .` menyalin source yang lolos `.dockerignore`. `EXPOSE 3000` mendokumentasikan port aplikasi; `-p` yang memublikasikan port.
- `CMD` menjalankan `server.js`. Aplikasi mendengarkan `0.0.0.0:3000` di container. Host mengakses `127.0.0.1:13005`; gunakan port lain jika 13005 sudah dipakai.
- `logs` menampilkan pesan `HTTP server listening on 0.0.0.0:3000`.

Uji melalui browser: <http://localhost:13005/> dan <http://localhost:13005/health>.

Linux/macOS/Git Bash:

```sh
curl -i http://localhost:13005/
curl -i http://localhost:13005/health
```

PowerShell Windows:

```powershell
curl.exe -i http://localhost:13005/
curl.exe -i http://localhost:13005/health
```

`/` harus menghasilkan HTTP 200 dan informasi Node.js. `/health` harus menghasilkan HTTP 200 dan `{"status":"ok"}`. `-i` menampilkan header HTTP beserta body.

## 2. Image dengan builder dan runtime

```sh
docker build -f Dockerfile.multistage -t lab05-theory-node:multistage .
docker run -d --name lab05-theory-node-multistage -p 127.0.0.1:13006:3000 lab05-theory-node:multistage
docker logs lab05-theory-node-multistage
docker exec lab05-theory-node-multistage id -u
```

`-f` memilih Dockerfile lain. Stage `builder` menjalankan `npm run build`; pada contoh ini `scripts/build.js` menyalin source menjadi `dist/server.js`. Stage `runner` menyalin metadata dan hasil build yang diperlukan saja. Keduanya memakai keluarga Debian Bookworm untuk menghindari perbedaan libc ketika contoh diperluas dengan dependency native.

`NODE_ENV=production` tersedia saat runtime. `USER node` menjalankan aplikasi sebagai user non-root; perintah `id -u` harus menghasilkan `1000`. Image sederhana dipakai untuk mengenalkan instruksi; contoh multistage menunjukkan pemisahan proses build dan user runtime.

Uji browser: <http://localhost:13006/> dan <http://localhost:13006/health>.

Linux/macOS/Git Bash:

```sh
curl -i http://localhost:13006/
curl -i http://localhost:13006/health
```

PowerShell Windows:

```powershell
curl.exe -i http://localhost:13006/
curl.exe -i http://localhost:13006/health
```

Harapkan HTTP 200. Respons `/` menampilkan `environment: production`. Multi-stage tidak menjamin image selalu lebih kecil; bandingkan ukuran hasil build sendiri:

```sh
docker image ls lab05-theory-node
```

## 3. Observasi dan pembersihan

```sh
docker ps --filter name=lab05-theory-node
docker stop lab05-theory-node-simple lab05-theory-node-multistage
docker rm lab05-theory-node-simple lab05-theory-node-multistage
```

Perintah ini hanya menghentikan dan menghapus dua container contoh. Image tetap tersimpan untuk demonstrasi berikutnya. Jika nama container sudah ada, periksa `docker ps -a` dan gunakan nama berbeda pada `docker run`; jangan menghapus container lain tanpa memeriksa pemiliknya.

Jika Docker melaporkan port dipakai, ganti bagian host, misalnya `127.0.0.1:13007:3000`, lalu sesuaikan URL. Jika koneksi belum siap, periksa `docker logs` dan ulangi permintaan HTTP setelah server mulai. Jika bagian `Server` tidak muncul pada `docker version`, jalankan Docker Desktop/Engine terlebih dahulu.

Tag seperti `node:24-alpine` dapat berubah. Untuk build yang dapat diulang lebih ketat, simpan digest base image serta lockfile dan catat platform build.

Referensi resmi: [Dockerfile](https://docs.docker.com/reference/dockerfile/), [multi-stage builds](https://docs.docker.com/build/building/multi-stage/), [Node.js releases](https://nodejs.org/en/about/previous-releases).
