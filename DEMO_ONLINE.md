# Demo teori Docker minggu 5 — cukup browser

**Bisa dijalankan sepenuhnya melalui browser tanpa memasang Docker, Python, Node.js, Git, atau VS Code pada laptop.** Docker tetap dipasang dan berjalan pada mesin Linux cloud milik Codespaces; browser hanya menjadi editor, terminal, dan jendela aplikasi. Diperlukan akun GitHub, internet, serta kuota Codespaces yang tersedia.

Demo ini menghubungkan konsep teori dengan aplikasi Cloud Notes pada Lab 05. Kegiatan ini formatif dan **tidak menjadi tugas atau penilaian lab terpisah**. Proyek kelompok tetap dikerjakan oleh 3 mahasiswa, dengan presentasi pada minggu 7 dan 14 sesuai panduan proyek.

<!-- actual-online-screenshots -->

Bukti di bawah diambil dari Chrome pada **8 Oktober 2026**, setelah membuat Codespace 2 core dari repo ini. Semua tahap build, run, HTTP, browser, restart, dan cleanup benar-benar dijalankan. Angka versi Docker, digest, ID catatan, serta nama Codespace dapat berbeda saat diulang.

## 1. Cerita pembuka: resep, paket makanan, dan dapur

Bayangkan tim membuka beberapa cabang restoran. Mereka ingin setiap cabang menjalankan cara memasak yang sama.

| Istilah Docker | Perumpamaan | Hal yang benar secara teknis |
|---|---|---|
| `Dockerfile` | Resep: bahan, urutan kerja, cara menyajikan | Instruksi untuk membangun image. Bukan aplikasi yang sedang berjalan. |
| Build context | Bahan yang tersedia untuk resep | File yang boleh digunakan build; `.dockerignore` menyaring file yang tidak diperlukan. |
| Image | Paket bahan dan alat yang sudah disiapkan | Artefak aplikasi beserta dependensi dan metadata; dapat dipakai membuat beberapa container. |
| Container | Satu dapur yang sedang mengerjakan paket tersebut | Proses terisolasi dari image, dengan lapisan tulisnya sendiri; berbagi kernel host. |
| Registry | Gudang paket yang dapat diambil cabang lain | Tempat menyimpan dan mengambil image, misalnya Docker Hub. |
| `-p 8000:8000` | Nomor pintu pelayanan di luar → nomor pintu di dalam | Port mesin tempat Docker berjalan → port aplikasi di container. Angkanya boleh berbeda. |
| `APP_ENV=classroom` | Instruksi operasional untuk cabang kelas | Environment variable yang diberikan saat container dijalankan; bukan secret pada demo ini. |
| Multi-stage build | Dapur persiapan dipisahkan dari paket yang dikirim | Hasil dari builder dipilih untuk runtime; alat build tidak perlu ikut semuanya. |

**Batas perumpamaan:** image bukan mesin virtual dengan kernel sendiri. Resep saja juga tidak menjamin hasil byte-identik apabila base image, dependensi, platform, atau konteks build berubah. Tag image dapat dipindah; digest mengidentifikasi konten image.

Pertanyaan pembuka: “Kalau resep tidak berubah, apakah dapur otomatis sudah berjalan?” Jawaban: belum; `docker build` membuat image, sedangkan `docker run` membuat dan menjalankan container.

## 2. Buka lingkungan online

1. Buka [repo meet5CloudService](https://github.com/SeedFlora/meet5CloudService) dan login ke GitHub.
2. Pastikan branch **main** dipilih.
3. Klik tombol **Code** → tab **Codespaces** → **Create codespace on main**. Pilih mesin **2 core** jika opsi ukuran mesin ditampilkan. Untuk memilihnya lebih awal, buka menu tiga titik di tab Codespaces → **New with options**, pilih branch main dan tipe 2 core.
4. Tunggu sampai editor VS Code di browser dan terminal siap. Inisialisasi pertama memerlukan waktu karena image lingkungan dan fitur Docker diambil dari internet.
5. Bila terminal belum tampak, pilih menu **Terminal → New Terminal**. Terminal ini adalah Linux di cloud.
6. Jalankan pemeriksaan berikut dari folder repo:

**Screenshot 01 — Pilih branch main, konfigurasi Docker, dan mesin 2 core**

![Pilih branch main, konfigurasi Docker, dan mesin 2 core](screenshots/online/01_create_codespace_2core.jpg)

Command / langkah: `Code → Codespaces → New with options → Create codespace`. Ini membuat mesin Linux cloud dari konfigurasi repo. Tidak memasang Docker pada laptop.


```bash
bash scripts/demo-online.sh check
```

**Screenshot 02 — Docker client dan daemon tersedia**

![Docker client dan daemon tersedia](screenshots/online/02_docker_check.jpg)

Command / langkah: `bash scripts/demo-online.sh check`. Client mengirim command; Server/daemon membangun image dan menjalankan container. Versi berbeda masih wajar; yang penting keduanya siap.


**Yang harus terlihat:** bagian `Client` dan `Server` pada `docker version`, kemudian versi `curl`. Jika `Client` muncul tetapi `Server` gagal, daemon belum siap; tunggu inisialisasi dan jalankan pemeriksaan lagi.

Konfigurasi `.devcontainer/devcontainer.json` menyiapkan Docker melalui fitur Docker-in-Docker. Aplikasi kelas **tidak otomatis dibuild atau dijalankan** saat workspace dibuka, sehingga dosen dapat memperlihatkan proses build secara bertahap.

**Jangan tertukar dengan `github.dev`:** menekan titik `.` di halaman GitHub membuka editor ringan; editor itu tidak menyediakan mesin compute dan terminal untuk menjalankan Docker. Gunakan **Codespaces**, yang alamat editornya dapat berakhiran `github.dev` tetapi memiliki nama Codespaces dan terminal Linux.

## 3. Lihat resep, lalu build image

Tampilkan resep asli Lab 05:

```bash
cat Dockerfile
```

**Screenshot 03 — Resep aplikasi pada repo**

![Resep aplikasi pada repo](screenshots/online/02b_dockerfile.jpg)

Command / langkah: `cat Dockerfile`. Membaca file tanpa mengubahnya. Cocokkan FROM, RUN, COPY, USER, EXPOSE, dan CMD dengan penjelasan di bawah.


Penjelasan yang ditunjukkan sambil membaca file:

- `FROM ... AS builder`: pilih lingkungan Python untuk tahap persiapan.
- `WORKDIR /build`: tentukan direktori kerja, tanpa mengandalkan `RUN cd` pada instruksi sebelumnya.
- `COPY requirements.txt .`: salin daftar dependensi lebih dahulu agar cache instalasi dapat digunakan ketika kode aplikasi saja berubah.
- `RUN ...`: buat virtual environment dan pasang dependensi saat **build**.
- `FROM ... AS runtime`: mulai tahap image runtime baru.
- `COPY --from=builder ...`: ambil virtual environment hasil builder ke runtime.
- `COPY app ./app`: masukkan kode API.
- `USER appuser`: jalankan aplikasi dengan user bukan root.
- `EXPOSE 8000`: dokumentasikan port aplikasi; instruksi ini **tidak** memublikasikan port.
- `CMD [...]`: perintah default ketika container mulai berjalan. Perintah ini tidak dieksekusi ketika build.

Build image:

```bash
bash scripts/demo-online.sh build
```

**Screenshot 04 — Build image berhasil**

![Build image berhasil](screenshots/online/02c_build_image.jpg)

Command / langkah: `bash scripts/demo-online.sh build`. FINISHED dan nama cloud-notes-api:theory-online menunjukkan image dibangun. Build belum menjalankan server.


Script menjalankan padanan berikut:

```bash
docker build --tag cloud-notes-api:theory-online .
```

`--tag` memberi nama image; titik `.` merupakan build context. Pada pengulangan build, sebagian langkah dapat menampilkan **CACHED**. Bandingkan “resep dibaca” dengan “paket sudah tersedia”; build belum membuka web aplikasi.

```bash
docker image ls cloud-notes-api
```

Ukuran image bergantung pada base image, dependensi, platform, dan implementasi; bandingkan angka yang benar-benar muncul pada lingkungan kelas.

## 4. Jalankan container dan lihat status Docker

```bash
bash scripts/demo-online.sh start
```

**Screenshot 05 — Cache build dan container siap**

![Cache build dan container siap](screenshots/online/02d_start_container.jpg)

Command / langkah: `bash scripts/demo-online.sh start`. CACHED menunjukkan input build yang dapat digunakan ulang. API siap setelah health merespons; port host dan container sama-sama 8000 pada demo.


Jika container belum ada, script membuild image lalu menjalankan:

```bash
docker run --detach --name cloudlab-theory-online \
  --label edu.binus.cloud-services.demo=week05-online \
  --publish 8000:8000 \
  --env APP_ENV=classroom \
  cloud-notes-api:theory-online
```

| Bagian command | Fungsi |
|---|---|
| `--detach` | Proses tetap berjalan di latar belakang; terminal kembali menerima perintah. |
| `--name` | Nama mudah dibaca untuk log, pemeriksaan, dan cleanup. |
| `--label` | Penanda kepemilikan demo, agar script menolak mengubah container lain yang kebetulan bernama sama. Bukan mekanisme autentikasi. |
| `--publish 8000:8000` | Hubungkan port 8000 mesin cloud dengan port 8000 container. |
| `--env APP_ENV=classroom` | Konfigurasi runtime tanpa mengubah image. Jangan gunakan pola ini untuk menampilkan secret saat presentasi. |
| Nama image | Paket aplikasi yang dipakai untuk membuat container. |

```bash
bash scripts/demo-online.sh status
```

**Screenshot 06 — Status Up, port, UID, dan log**

![Status Up, port, UID, dan log](screenshots/online/03_status_container.jpg)

Command / langkah: `bash scripts/demo-online.sh status`. Up menunjukkan proses berjalan. Mapping 8000 menuju port aplikasi; UID 10001 adalah user bukan root. Log Uvicorn menunjukkan server listen 0.0.0.0:8000.


**Yang diamati:** nama container, image, status `Up`, mapping port, user runtime `uid=10001`, dan log Uvicorn. Daemon Docker dan proses aplikasi berjalan di cloud, bukan di laptop penonton.

Script tidak memakai `docker system prune`, tidak menghapus image lain, dan menolak container yang label kepemilikannya tidak sesuai. Memanggil `start` lagi menggunakan ulang container demo yang sudah ada. Setelah kode berubah, jalankan `stop` lalu `start` agar container baru memakai image terbaru.

## 5. Tampilkan web/Swagger di layar kelas

1. Buka tab **Ports** pada panel bawah editor Codespaces.
2. Temukan port **8000** dengan label **Cloud Notes API / Swagger**. Jika belum terlihat, pilih **Add Port / Forward a Port**, masukkan `8000`.
3. Pertahankan **Port Visibility: Private**. Dosen yang login dapat membuka aplikasi; presentasi cukup membagikan layar dosen.
4. Klik ikon globe atau **Open in Browser**. GitHub membuat URL forwarding HTTPS.
5. Tambahkan **`/docs`** pada URL tersebut. Halaman Swagger menampilkan daftar endpoint API.

**Screenshot 07 — Forwarded port 8000 dengan akses Private**

![Forwarded port 8000 dengan akses Private](screenshots/online/03b_ports_private.jpg)

Command / langkah: `Ports → 8000 → Open in Browser → /docs`. Forwarding GitHub menambahkan URL browser ke port host cloud; berbeda dari mapping -p milik Docker.


**Screenshot 08 — GET health lewat browser menghasilkan HTTP 200**

![GET health lewat browser menghasilkan HTTP 200](screenshots/online/05_swagger_health.jpg)

Command / langkah: `GET /health → Try it out → Execute`. Padanan di terminal Codespaces: curl -i http://127.0.0.1:8000/health. status ok menunjukkan liveness API, belum koneksi database.


**Jangan mengetik `http://localhost:8000` pada address bar laptop:** alamat itu menunjuk ke laptop. Gunakan URL pada tab Ports. `localhost` pada terminal Codespaces menunjuk ke mesin cloud, sehingga `curl http://127.0.0.1:8000/health` memang benar di terminal tersebut. Aplikasi di dalam container melayani HTTP; URL HTTPS forwarding disediakan oleh layanan GitHub.

Urutan demonstrasi di Swagger:

1. **GET `/health`** → **Try it out → Execute**. Respons HTTP 200 menunjukkan aplikasi melayani permintaan.
2. **GET `/runtime`** → Execute. Respons menunjukkan `environment: classroom` dan `storage: memory`; kaitkan dengan `--env` pada `docker run`.
3. **POST `/notes`** → Try it out, masukkan contoh di bawah, lalu Execute. Respons HTTP 201 membuat catatan dan menghasilkan `id`.

```json
{
  "title": "Demo Docker teori",
  "content": "Aplikasi yang sama berjalan pada mesin cloud."
}
```

4. **GET `/notes`** → Execute. Catatan yang baru dibuat muncul dalam daftar.
5. **POST `/notes`** dengan `title` berisi spasi saja → HTTP 422. API memvalidasi input; container hidup bukan berarti semua request pasti valid.
6. **GET `/notes/{note_id}`** dengan `note_id` **0** → HTTP 404. ID 0 tidak dibuat oleh aplikasi ini.

**Screenshot 09 — POST catatan berhasil dengan HTTP 201**

![POST catatan berhasil dengan HTTP 201](screenshots/online/05b_swagger_post_201.jpg)

Command / langkah: `POST /notes → Try it out → isi JSON → Execute`. Payload screenshot adalah title Demo kelas online dan content Docker berjalan di cloud. Curl di screenshot memperlihatkan method, Content-Type, dan body. ID 3 adalah hasil uji ini; pada sesi baru ID dapat berbeda.


**Screenshot 10 — GET daftar membaca catatan yang dibuat**

![GET daftar membaca catatan yang dibuat](screenshots/online/05c_swagger_list.jpg)

Command / langkah: `GET /notes → Try it out → Execute`. Padanan terminal: curl -i http://127.0.0.1:8000/notes. Daftar memuat catatan dari script test dan POST browser. HTTP 200 tidak membuktikan data persisten.


Screenshot utama yang berguna untuk catatan kelas: terminal build, status container + port, tab Ports, Swagger `/health`, hasil POST 201, daftar catatan, dan daftar kosong setelah restart. Tampilkan command yang menghasilkan setiap screenshot dan jelaskan outputnya.

## 6. Pemeriksaan end to end dan data sementara

Untuk memperlihatkan pemeriksaan otomatis yang menguji aplikasi sungguhan:

```bash
bash scripts/demo-online.sh test
```

**Screenshot 11 — Pemeriksaan end to end lulus**

![Pemeriksaan end to end lulus](screenshots/online/04_http_tests.jpg)

Command / langkah: `bash scripts/demo-online.sh test`. 200 untuk baca/health/docs; 201 untuk create; 422 untuk judul kosong; 404 untuk ID 0. PASS mengikuti respons layanan sungguhan.


Script memeriksa respons `/health`, nilai `APP_ENV`, membuat catatan, membaca catatan tersebut, memeriksa daftar, menolak input kosong dengan HTTP 422, memeriksa HTTP 404, dan membuka `/docs`. **PASS** diberikan setelah HTTP status dan isi penting sesuai; halaman Swagger sendiri tidak dicetak seluruhnya ke terminal.

Demonstrasi sifat in-memory:

```bash
bash scripts/demo-online.sh test --restart
```

**Screenshot 12 — Restart mengosongkan data memori**

![Restart mengosongkan data memori](screenshots/online/06_restart_memory.jpg)

Command / langkah: `bash scripts/demo-online.sh test --restart`. Setelah docker restart, GET /notes menghasilkan []. Image masih ada. Memori proses tidak menjadi persisten hanya karena diberi volume.


Command ini membuat catatan uji, me-restart **container demo**, lalu memastikan GET `/notes` menghasilkan `[]`. Data hilang karena dict Python disimpan dalam memori proses. Restart proses saja sudah menghapusnya; menambahkan volume tidak otomatis membuat dict menjadi database. Database dan persistensi akan dikembangkan pada tahapan proyek berikutnya.

Ini pertanyaan diskusi formatif, beserta jawabannya: “Apakah image terhapus saat container restart?” **Tidak.** Image masih ada. Yang hilang pada contoh ini adalah data di memori proses aplikasi.

## 7. Berhenti setelah kelas

Jika memilih demo tambahan, lakukan [Docker Scout](#11-docker-scout-opsional-510-menit) atau [Compose tiga layanan](COMPOSE_DEMO.md) sebelum menghentikan Codespace. Keduanya opsional; alur API inti di atas harus berhasil terlebih dahulu.

Hapus container demo sendiri:

```bash
bash scripts/demo-online.sh stop
```

**Screenshot 13 — Container demo dibersihkan**

![Container demo dibersihkan](screenshots/online/07_stop_container.jpg)

Command / langkah: `bash scripts/demo-online.sh stop`. Menghapus hanya container bernama dan berlabel milik demo. Image tetap tersedia; container lain tidak dibersihkan.


Image tetap tersedia sehingga build berikutnya dapat memakai cache. Semua catatan demo sementara hilang. Script tidak mengubah container lain.

Selanjutnya hentikan **Codespaces**, bukan hanya menutup tab: buka [github.com/codespaces](https://github.com/codespaces), pilih menu **…** di Codespace kelas → **Stop codespace**. Menghentikan Codespace menghentikan penggunaan compute; penyimpanan tetap dihitung selama Codespace masih ada.

**Screenshot 14 — Codespace sudah Stopped**

![Codespace sudah Stopped](screenshots/online/08_codespace_stopped.jpg)

Command / langkah: `github.com/codespaces → menu … → Stop codespace`. Stopped menghentikan compute. Lingkungan disimpan untuk dibuka kembali, sehingga storage masih dihitung. Menutup tab saja bukan langkah penghentian.


Pada **8 Oktober 2026**, akun personal GitHub Free mendapat **120 core-hours compute** dan **15 GB-month storage** per bulan. Mesin 2 core mengonsumsi 2 core-hours untuk satu jam aktif, sehingga 120 core-hours setara sekitar 60 jam aktif pada mesin itu. Kuota bersama penggunaan Codespaces lain pada akun; bukan jaminan gratis tanpa batas. Detail dan kebijakan terbaru: [GitHub Codespaces billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces).

Jika Codespace akan **dihapus**, commit dan push perubahan yang ingin disimpan terlebih dahulu. Penghapusan membuang perubahan yang belum tersimpan di remote. Untuk demo tanpa perubahan kode, cukup Stop setelah kelas; hapus lingkungan jika sudah tidak diperlukan.

## 8. Jalur cadangan: Killercoda Docker Playground

Gunakan [Killercoda Docker Playground](https://killercoda.com/playgrounds/scenario/docker) jika Codespaces tidak tersedia. Login sesuai permintaan layanan, tunggu terminal siap, lalu jalankan:

```bash
git clone https://github.com/SeedFlora/meet5CloudService.git
```

```bash
cd meet5CloudService
```

```bash
bash scripts/demo-online.sh check
```

```bash
bash scripts/demo-online.sh start
```

```bash
bash scripts/demo-online.sh test
```

Untuk web, buka panel **Traffic / Port Access** pada antarmuka playground, masukkan port **8000**, lalu tambahkan `/docs` pada URL yang diberikan. Nama menu dapat berbeda menurut antarmuka layanan. Untuk demonstrasi terminal saja, `curl` dan script tetap dapat ditampilkan tanpa membuka akses web. URL akses Killercoda bukan port private berautentikasi seperti Codespaces; gunakan hanya data dummy demo.

Sesi gratis Killercoda dibatasi sekitar **1 jam per lingkungan** dan bersifat sementara; setelah sesi berakhir lingkungan dihapus. Jangan menaruh data kelas penting atau secret produksi di dalamnya. Simpan perubahan ke repo milik sendiri sebelum lingkungan hilang. Rincian: [FAQ resmi Killercoda](https://killercoda.com/faq).

**Play with Docker tidak digunakan:** [pengumuman pada repo resminya](https://github.com/play-with-docker/play-with-docker) menyatakan layanan tidak tersedia mulai 1 Maret 2026. Gunakan Codespaces atau playground yang masih tersedia.

## 9. Kendala umum

| Gejala | Langkah |
|---|---|
| Tidak ada terminal Linux / Docker di editor GitHub | Pastikan membuka **Codespaces**, bukan editor ringan `github.dev`. |
| Docker daemon belum siap | Tunggu proses konfigurasi, jalankan `docker version` dan `check` lagi. Jika konfigurasi repo baru ditambahkan pada Codespace lama, **Codespaces: Rebuild Container**; simpan perubahan dulu. |
| Kuota habis / pembuatan Codespace ditolak | Periksa kuota akun dan gunakan Killercoda sebagai cadangan. |
| Port 8000 sudah dipakai | Jalankan `DEMO_PORT=18005 bash scripts/demo-online.sh start`; gunakan awalan yang sama untuk `test` dan `status`. Forward port 18005 secara manual pada tab Ports. |
| Script menolak nama container | Ada container lain dengan nama demo tetapi label berbeda. Jangan menghapusnya tanpa memeriksa pemiliknya. Gunakan Codespace baru untuk kelas. |
| Browser menampilkan 404 di `/` | Aplikasi ini tidak membuat homepage. Buka **`/docs`**, `/health`, atau `/runtime`. |
| Gagal mengakses `localhost` dari browser laptop | Buka URL HTTPS pada tab **Ports**. |
| Kode diubah tetapi respons lama | `stop`, lalu `start`; container lama tidak otomatis diganti ketika image dibuild ulang. |
| Catatan hilang sesudah restart | Perilaku yang diharapkan: penyimpanan masih di memori proses. |

## 10. Sumber resmi

- [GitHub Codespaces quickstart](https://docs.github.com/en/codespaces/quickstart): pembuatan lingkungan melalui browser.
- [Port forwarding di Codespaces](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace): port dan visibility.
- [Docker-in-Docker Feature](https://github.com/devcontainers/features/tree/main/src/docker-in-docker): Docker pada dev container.
- [Referensi Dockerfile](https://docs.docker.com/reference/dockerfile/): instruksi dan perilakunya.
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/): pemisahan builder dan runtime.
- [Build secrets](https://docs.docker.com/build/building/secrets/): gunakan secret mounts untuk kebutuhan build, bukan ARG/ENV untuk secret.
- [Codespaces billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces) dan [Killercoda FAQ](https://killercoda.com/faq): batas penggunaan.

## 11. Docker Scout opsional 5–10 menit

**Kasus rilis tim:** image berhasil dibuild dan API memberikan respons yang diharapkan. Sebelum rilis, tim meninjau daftar paket software, advisory kerentanan, dan pilihan perbaikan. Scout mengenali komponen image sebagai **SBOM** (Software Bill of Materials), lalu mencocokkan paket dan versinya dengan advisory. [Docker Scout](https://docs.docker.com/scout/)

**Perumpamaan restoran:** SBOM adalah daftar bahan dan nomor batch. Scout mencocokkan daftar itu dengan recall produsen. Mengganti bahan harus diikuti memasak dan mencoba hidangan kembali—dalam software, ubah dependency/base, rebuild, uji aplikasi, lalu scan ulang. Analogi ini bukan klaim bahwa CVE adalah tanggal kedaluwarsa atau scan menguji semua fungsi aplikasi.

### 11.1. Persiapan sebelum kelas

- Codespace dan Docker daemon sudah berjalan; API inti sudah diuji. Image target adalah **`cloud-notes-api:theory-online`**, bukan image dari contoh Compose.
- Docker Desktop menyertakan plugin Scout; Engine pada Codespaces belum tentu menyertakannya. Helper kelas memakai binary standalone tersendiri di mesin Linux cloud. Laptop tidak perlu dipasangi plugin. [Instalasi resmi Scout](https://docs.docker.com/scout/install/)
- Siapkan akun Docker dan autentikasi **sebelum screen sharing**, sesuai prasyarat layanan yang digunakan. Jangan merekam password, PAT, device code aktif, atau isi `~/.docker/config.json`. Helper tidak melakukan login. [Quickstart Scout](https://docs.docker.com/scout/quickstart/), [Docker login](https://docs.docker.com/reference/cli/docker/login/)

Dari root repo pada terminal Linux:

```bash
bash scripts/demo-online.sh build
bash scripts/scout-demo.sh install
bash scripts/scout-demo.sh check
```

`install` adalah tindakan eksplisit, memakai release **Scout 1.26.0** dan memverifikasi checksum unduhannya. Binary standalone dipasang ke cache pengguna khusus demo; script tidak menimpa plugin atau konfigurasi login lain. Instalasi valid yang sudah ada akan diperiksa dan dipakai ulang. `check` memperlihatkan binary/daemon/image dan versi, **belum menguji login atau akses layanan Scout**. Waktu provisioning, unduhan, serta login di luar slot show 5–10 menit. Keberadaan plugin Desktop lain tidak menggantikan cache binary yang digunakan helper ini.

Scout mengakses layanan online dan dapat memerlukan autentikasi atau hak akses akun. `local://` mengharuskan target berada di image store lokal; ini **bukan** mode scan sepenuhnya offline. Tidak perlu `docker push`, enrollment image, atau enable repository monitoring untuk alur kelas ini. Fitur/paket layanan mengikuti akun Docker; jangan menganggap semua layanan gratis tanpa batas. [Konfigurasi CLI](https://docs.docker.com/scout/how-tos/configure-cli/), [harga Docker](https://www.docker.com/pricing/)

### 11.2. Show bersama: ringkasan → rincian → pilihan perbaikan

| Menit | Command | Pertanyaan yang dijelaskan |
|---|---|---|
| 0–2 | `bash scripts/scout-demo.sh quickview` | Image mana yang diperiksa? Apa perbedaan total image dengan base? |
| 2–5 | `bash scripts/scout-demo.sh cves` | Paket dan versi apa yang terdampak? Apa ID, severity, dan versi perbaikannya? |
| 5–7 | `bash scripts/scout-demo.sh recommendations` | Adakah kandidat base yang lebih baru? Apa yang masih perlu diuji? |
| 7–10 | Diskusi keputusan dan siklus rebuild/test/scan | Mengapa update belum otomatis memperbaiki container yang sedang berjalan? |

```bash
bash scripts/scout-demo.sh quickview
bash scripts/scout-demo.sh cves
bash scripts/scout-demo.sh recommendations
```

Padanan pada **plugin Docker Desktop** untuk image dengan tag yang sama; pada Codespaces gunakan helper di atas karena binary helper bukan plugin `docker scout`:

```bash
docker scout quickview local://cloud-notes-api:theory-online
docker scout cves local://cloud-notes-api:theory-online
docker scout recommendations local://cloud-notes-api:theory-online
```

**`quickview`:** ringkasan kerentanan image dan base yang teridentifikasi. C/H/M/L/U berarti critical/high/medium/low/unspecified. Angka tidak tetap: tag, digest, platform, dependency, advisory, dan waktu scan dapat mengubah hasil. Pastikan target benar sebelum membandingkan laporan. [Quickview](https://docs.docker.com/reference/cli/docker/scout/quickview/)

**`cves`:** rincian temuan per paket. Pilih satu temuan **yang benar-benar muncul** dan baca nama paket, versi terpasang, CVE ID, severity, affected range, dan fixed version jika tercatat. Pada plugin Desktop, opsi `--details` memberi rincian tambahan; helper menerima satu action dan tidak meneruskan flag tambahan. Jika daftar atau filter kosong, jelaskan cakupannya; jangan menambahkan angka atau CVE rekaan. [CVEs](https://docs.docker.com/reference/cli/docker/scout/cves/)

**`recommendations`:** kandidat refresh/update base image berdasarkan informasi yang tersedia. Command memberi saran, belum mengubah Dockerfile, image, atau container. Hasil tanpa rekomendasi juga mungkin terjadi; jangan mengklaim pasti tersedia base yang lebih aman atau kompatibel. [Recommendations](https://docs.docker.com/reference/cli/docker/scout/recommendations/)

<!-- scout-screenshots:start -->

**Konteks rekaman baseline:** screenshot instalasi/ringkasan/CVE di bawah diambil pada image API **sebelum perbaikan dependency kelas**, digest `c9751e34cb88`. Tag hanya nama yang dapat digunakan kembali; digest membedakan isi image. Saat membuild source repo yang telah diperbarui, gunakan hasil scan aktual Anda. Baseline dipakai untuk menjelaskan alasan perubahan dan dibandingkan dengan image hasil perbaikan.

#### Screenshot Scout 1 — instalasi dan pemeriksaan teknis

![Scout 1.26.0 standalone dan image lokal tersedia pada Codespaces](screenshots/scout/01_install_check.jpg)

**Command:** dari root repo, `bash scripts/scout-demo.sh install`, lalu `bash scripts/scout-demo.sh check`. **Fungsi/cara kerja:** installer memverifikasi binary pada cache pengguna; check membaca versi, kesiapan daemon, identitas/platform image lokal. **Baca hasil aktual:** Scout v1.26.0 Linux/amd64, daemon 29.8.2-1, target ID berawalan `sha256:c9751e34cb88`. Pesan check secara eksplisit menyebut akses layanan belum diuji; tahap berikut yang membuktikan analisis berhasil. Command `cd ../..` pada screenshot hanya kembali dari folder contoh Compose ke root repo.

#### Screenshot Scout 2 — ringkasan image yang benar

![Quickview menampilkan target lokal, digest, jumlah paket, dan severity](screenshots/scout/02_quickview.jpg)

**Command:** `bash scripts/scout-demo.sh quickview`. **Fungsi/cara kerja:** Scout menganalisis image lokal dan mencocokkan komponen dengan advisory yang tersedia. **Baca hasil aktual 8 Oktober 2026:** target `local://cloud-notes-api:theory-online`, digest pendek `c9751e34cb88`, 136 paket diindeks; target **0 critical, 4 high, 9 medium, 28 low**. Base teridentifikasi `python:3.12-slim` dengan 0 critical, 1 high, 6 medium, 27 low pada analisis itu. Ini snapshot hasil, bukan angka yang harus dihasilkan semua peserta. Keberhasilan layanan pada Codespace ini tidak membuktikan scan selalu dapat dijalankan tanpa akun atau hak akses pada lingkungan lain.

**Bagian legacy yang tampak:** CLI masih menampilkan `Policy status FAILED` dan `Health score E (22%)` pada screenshot aktual. Jangan membaca 22% sebagai persentase keamanan, nilai mahasiswa, atau tes fungsi API. Pengumuman resmi mencantumkan retirement fitur health scores dan sejumlah fitur dashboard Scout; kelas berfokus pada paket, CVE, severity, versi perbaikan, dan tindakan yang diuji, bukan mengejar skor tersebut. Output yang tampak tetap dicatat apa adanya. [Retired features Docker](https://docs.docker.com/retired/)

#### Screenshot Scout 3 — rincian paket dan batas perbaikan

![Daftar CVE menampilkan affected range, not fixed, dan ringkasan temuan aktual](screenshots/scout/03_cves.jpg)

**Command:** `bash scripts/scout-demo.sh cves`. **Fungsi/cara kerja:** menampilkan advisory per paket beserta versi, severity, rentang terdampak, dan fixed version bila diketahui. **Baca hasil aktual:** 41 temuan kerentanan pada 15 paket, dengan total 0C/4H/9M/28L. Cuplikan akhir memperlihatkan paket OS Debian `shadow` versi `1:4.17.4-2`, LOW `CVE-2007-5686`, serta `apt` versi `3.0.3`, LOW `CVE-2011-3374`; keduanya tampil dengan `Fixed version: not fixed`. Angka/rentang yang dicetak mengikuti advisory saat itu; jangan menyebut temuan ini high atau menambahkan versi fix rekaan.

**Kunci:** `not fixed` berarti data advisory pada hasil tersebut belum mencatat versi perbaikan. Tetap nilai penggunaan paket, konfigurasi, exposure, izin, dan mitigasi; jangan berasumsi mengubah baris `FROM` pasti menghapus semua temuan. Laporan lengkap memuat paket lain, termasuk empat high yang tidak terlihat pada potongan akhir ini.

#### Screenshot Scout 3b — pilih tindakan berdasarkan paket

![Rincian high memperlihatkan kandidat versi fix Starlette dan zlib not fixed](screenshots/scout/03b_high_packages.jpg)

**Command pada rekaman:** `grep -B 3 -A 8 'HIGH CVE' hasil/scout/*/cves.txt`. **Fungsi:** menampilkan baris high beserta konteks dari output tersimpan; ini membaca teks lokal, bukan scan baru. Wildcard dapat membaca lebih dari satu laporan bila folder sudah berisi banyak hasil. Untuk review, pilih `cves.txt` dari folder hasil **baseline yang tepat**, sesuai path yang dicetak helper, dan cocokkan metadata/digest sebelum membandingkan.

**Baca contoh nyata:** advisory Starlette pada output mencantumkan fixed version **1.3.1**, **1.1.0**, atau **0.49.1** untuk temuan yang berbeda. Paket OS **zlib** tampil dengan HIGH `CVE-2026-85091` dan `not fixed`. Nomor fix setiap advisory tidak otomatis menjadi satu versi yang kompatibel untuk seluruh aplikasi; resolusi dependency harus tetap memenuhi constraint FastAPI/Starlette dan diuji.

**Kunci keputusan:** temuan Starlette ditinjau melalui dependency aplikasi/constraint framework; temuan zlib ditinjau melalui base/OS dan mitigasi yang tersedia. Dosen menunjukkan pembaruan requirements yang kompatibel, build image dengan tag baru, tes API, lalu scan ulang. Jangan menyimpulkan semua endpoint API dapat dieksploitasi hanya dari severity; tinjau advisory serta penggunaan kode dan konteks runtime. Temuan tanpa fix tetap dicatat untuk follow-up.

#### Screenshot Scout 3c — installed → affected → fixed

![Starlette terpasang 0.46.2 dibandingkan dengan affected range dan fixed version](screenshots/scout/03c_starlette_example.jpg)

**Command pada rekaman:** `grep -B 1 -A 14 'pkg:pypi/starlette@' hasil/scout/20261008T033326Z-IJU7GH/cves.txt`. **Fungsi/cara kerja:** mengambil satu paket beserta advisory dari laporan baseline yang dipilih eksplisit; folder pada mesin Anda mengikuti path yang dicetak helper. **Baca hasil:** Starlette terpasang **0.46.2**. Untuk HIGH `CVE-2026-54283`, hasil mencantumkan rentang **>=0.4.1 dan <1.3.1**, fixed **1.3.1**; untuk HIGH `CVE-2026-48818`, rentang **<1.1.0**, fixed **1.1.0**.

**Kunci:** 0.46.2 berada dalam kedua rentang terdampak yang tampil. Update ke 1.1.0 saja belum melewati ambang fix 1.3.1 pada advisory pertama. Pilih framework/dependency yang kompatibel dan versi yang memenuhi perbaikan yang relevan, verifikasi versi hasil resolver di dalam image, lalu uji API/rescan. Jangan memaksakan versi Starlette di luar constraint FastAPI hanya untuk menurunkan angka.

**Konteks:** CVE-2026-54283 memerlukan parsing form urlencoded; CVE-2026-48818 terkait StaticFiles Windows, dengan POSIX tidak terdampak. Contoh API JSON/Linux tidak memakai kedua fitur tersebut. Paket terdeteksi belum membuktikan kondisi eksploitasi pada aplikasi; update kompatibel tetap diuji. [Advisory form parsing](https://github.com/Kludex/starlette/security/advisories/GHSA-82w8-qh3p-5jfq), [advisory Windows](https://github.com/Kludex/starlette/security/advisories/GHSA-wqp7-x3pw-xc5r)

#### Screenshot Scout 4 — saran base yang benar-benar tersedia

![Recommendations menyatakan base terbaru dan tidak menyediakan alternatif tag](screenshots/scout/04_recommendations.jpg)

**Command:** `bash scripts/scout-demo.sh recommendations`. **Fungsi/cara kerja:** layanan meninjau base target dan kandidat refresh/tag berdasarkan informasi yang tersedia; command hanya memberi informasi. **Baca hasil baseline:** base `python:3.12-slim` teridentifikasi dengan runtime **3.12.15**, tampil **This image version is up to date** dan **There are no tag recommendations at this time**. Base tetap memiliki 0C/1H/6M/27L pada scan ini. Tidak ada kandidat tag bukan kesimpulan semua paket aman.

**Kunci:** perbaikan tiga temuan high Starlette perlu meninjau dependency aplikasi, bukan memaksa mengganti `FROM` hanya agar ada rekomendasi. Saat ada kandidat base pada image lain, periksa kompatibilitas platform/runtime/library, rebuild, recreate, tes aplikasi, dan scan ulang. Pada hasil kelas ini jangan mengarang kandidat tag atau menyebut base update sebagai perbaikan yang sudah dilakukan.

#### Screenshot Scout 5 — laporan teks dan SARIF selesai

![Report menyelesaikan ekspor SARIF dan mencetak folder hasil lokal](screenshots/scout/05_report.jpg)

**Command:** `bash scripts/scout-demo.sh report`. **Fungsi/cara kerja:** helper menjalankan quickview → cves → recommendations → ekspor CVEs SARIF pada folder invocation baru. **Baca hasil baseline:** `Detected 15 vulnerable packages with a total of 41 vulnerabilities`, lalu **Report written to .../cves.sarif.json** dan pesan selesai beserta folder lokal. SARIF menyimpan temuan dalam format terstruktur untuk alat analisis; file itu bukan perbaikan paket atau bukti aplikasi aman. Metadata/exit code serta laporan generated diabaikan Git; buka dan kurasi hasil yang relevan untuk review tim tanpa kredensial. Pengumpulan laporan tidak diwajibkan pada lab ini.

<!-- scout-screenshots:end -->

### 11.3. Kunci diskusi: memilih tindakan sebelum rilis

| Situasi | Jawaban dan tindakan |
|---|---|
| Paket OS/base terdampak dan fix tersedia | Evaluasi base refresh/update; periksa dukungan runtime dan kompatibilitas, ubah `FROM`, rebuild, recreate container, uji HTTP, lalu scan ulang. |
| Dependency aplikasi terdampak | Periksa requirements/lockfile serta rentang terdampak. Pilih update yang sesuai, uji kontrak API dan dependency, lalu rebuild dan scan ulang. |
| Severity tinggi tetapi versi fix belum tercatat | Nilai penggunaan fitur rentan, akses jaringan, konfigurasi dan izin. Cari mitigasi atau penggantian komponen; catat keputusan serta bukti, jangan abaikan hanya karena belum ada fix. |
| Saran base tersedia | Saran bukan perubahan otomatis. Bandingkan runtime, library native, platform, ukuran, dan hasil tes sebelum menggunakan base baru. |
| Hasil 0 atau filter critical/high kosong | Tidak ada temuan dalam cakupan data/filter saat itu. Masih perlu tes fungsi, secret, konfigurasi, exposure, dan konteks runtime; jangan menyimpulkan aman mutlak. |
| Plugin/login/network/backend gagal | Scan belum memberikan hasil valid. Perbaiki prasyarat atau gunakan bukti aktual terdahulu yang diberi label image/digest dan tanggal. Gagal scan bukan 0 CVE dan bukan otomatis API gagal. |

**Siklus kerja tim:** identifikasi paket → nilai risiko dan fix → update yang sesuai → build image baru → ganti container → uji health/POST/GET/validasi → scan ulang. Rebuild saja tidak mengganti container yang sudah ada. Untuk API memori Lab 05, recreate/restart menghapus catatan sementara; gunakan data dummy ketika menguji.

Dalam presentasi kelompok minggu 7 dan 14, bukti ini dapat membantu menjelaskan alasan memilih base/dependency dan perubahan yang benar-benar diuji. Tidak ada tugas, penyerahan, atau nilai Scout/lab terpisah. Kelompok tetap **3 mahasiswa**.

### 11.4. Laporan lokal dan kendala

```bash
bash scripts/scout-demo.sh report
```

Setiap action scan membuat folder `hasil/scout/<waktu-UTC>-<acak>/`, menyimpan output dan exit code serta `metadata.txt`. Action `report` menjalankan quickview, CVEs, recommendations, lalu ekspor SARIF secara berurutan: `quickview.txt`, `cves.txt`, `recommendations.txt`, `cves.sarif.json`, dan `cves-sarif.console.txt`. Proses berhenti pada kegagalan pertama, sehingga sebagian file mungkin belum ada. Folder generated diabaikan Git. Laporan parsial/gagal harus tetap diberi status tersebut; jangan menyebutnya scan lulus. Exit 0 berarti command selesai, bukan jaminan image bebas kerentanan. Tidak diperlukan commit/push laporan untuk latihan kelas.

Untuk image lain yang sudah ada secara lokal di Linux, ubah target secara eksplisit, misalnya `SCOUT_IMAGE=cloud-notes-api:lab05 bash scripts/scout-demo.sh quickview`. Script tidak membuild image tersebut secara otomatis. Jangan tertukar dengan image backend Compose. Lihat `bash scripts/scout-demo.sh help` untuk opsi helper.

| Gejala | Tindakan |
|---|---|
| Binary helper belum tersedia | Jalankan `install` di terminal Linux cloud dan ulangi `check`; Docker Desktop lokal dapat memakai plugin bawaannya dengan CLI langsung. |
| Image target tidak ditemukan | Build API inti dahulu dan periksa `docker image ls cloud-notes-api`; gunakan tag yang sama dengan target helper. |
| Diminta login atau hak akses | Siapkan akun/autentikasi sebelum presentasi; jangan mencetak konfigurasi kredensial. Jika akses tidak tersedia, lanjutkan materi inti memakai rekaman valid. |
| Backend tidak dapat diakses | Periksa jaringan/layanan. Hasil gagal bukan laporan tanpa kerentanan. |
| Rekomendasi tidak muncul | Baca keterangan command; informasi base atau kandidat mungkin tidak tersedia. Ini tidak membuktikan base sudah aman. |
| Total berbeda dari screenshot | Cocokkan digest, tag, platform, filter, versi Scout, dan waktu advisory. Gunakan hasil aktual Anda. |

Dokumentasi Scout menyatakan analisis sekali jalan CLI/Desktop tidak menyimpan data image pada Scout; repository monitoring menyimpan snapshot metadata. Pernyataan itu tidak berarti tidak ada request jaringan atau metadata yang pernah dikirim. Gunakan image demo yang sesuai dan simpan hanya hasil tanpa kredensial. [Analisis image](https://docs.docker.com/scout/explore/analysis/), [konfigurasi CLI](https://docs.docker.com/scout/how-tos/configure-cli/)

### 11.5. Perbaikan yang dijalankan: update → tes → scan ulang

**Kasus:** tiga high pada baseline berkaitan dengan Starlette. Requirements API utama diperbarui menjadi **FastAPI 0.142.4** dan **Uvicorn 0.54.0**; pada build kelas, resolver memasang **Starlette 1.7.0**. Pin direct dependency bukan lock seluruh paket transitif, sehingga versi yang benar-benar terpasang diperiksa di container. Route/input JSON, user UID 10001, dan penyimpanan memori tetap diuji. Pengujian regresi lokal API + kunci stats meluluskan **21/21 pemeriksaan**; show Codespaces berikut membuktikan API dari image baru berjalan.

Pada pengambilan bukti, pengajar menandai image baseline menjadi `cloud-notes-api:scout-before` **sebelum rebuild**. Screenshot lama tetap berlabel digest `c9751e34cb88`; tag `theory-online` kemudian menunjuk build terbaru. Peserta cukup memakai source repo terbaru dan mengulang pengujian; tidak perlu memasang ulang dependency lama untuk membuat angka baseline sama.

Dari **root repo**, buat kembali container demo dari source yang diperbarui:

```bash
bash scripts/demo-online.sh stop
bash scripts/demo-online.sh start
bash scripts/demo-online.sh test --restart
docker exec cloudlab-theory-online python -c \
  'import fastapi, starlette, uvicorn; print("VERSIONS", fastapi.__version__, starlette.__version__, uvicorn.__version__)'
docker tag cloud-notes-api:theory-online cloud-notes-api:scout-improved
SCOUT_IMAGE=cloud-notes-api:scout-improved bash scripts/scout-demo.sh quickview
SCOUT_IMAGE=cloud-notes-api:scout-improved bash scripts/scout-demo.sh cves
```

`stop` memeriksa kepemilikan label lalu menghapus container demo; `start` membuild source dan membuat container baru. Operasi ini serta `test --restart` sengaja menghapus catatan API memori, jadi gunakan data dummy. Jika memakai `DEMO_PORT` alternatif, terapkan nilai yang sama pada command wrapper; snapshot ini memakai host **8000**. `docker exec` membaca versi dari proses lingkungan container, bukan dari asumsi requirements. `docker tag` memberi nama lokal tambahan pada **image yang sama**, tanpa upload atau mengganti container. Awalan `SCOUT_IMAGE` memilih target helper untuk invocation itu; jangan memakai default lalu mengaku memeriksa tag lain.

![API hasil pembaruan dependency lulus pengujian HTTP dan reset memori](screenshots/scout/06_improved_tests.jpg)

**Command aktual:** `bash scripts/demo-online.sh test --restart`, `docker exec ... python -c ...`, lalu `docker tag ...:theory-online ...:scout-improved`. **Fungsi/cara kerja:** ulangi health/runtime/create/read/validasi/missing/docs, restart proses, baca versi dependency dalam container, dan beri tag kandidat. **Baca hasil:** semua pemeriksaan demo PASS; sesudah restart `/notes` = `[]`; VERSIONS **0.142.4 1.7.0 0.54.0** dalam urutan FastAPI/Starlette/Uvicorn. `/runtime` API ini memakai `environment: classroom` dan `storage: memory`; contoh Compose memakai field `app_env` dan storage postgres.

![Quickview image hasil pembaruan menurunkan temuan dan tetap menyisakan risiko](screenshots/scout/07_improved_quickview.jpg)

**Command:** `SCOUT_IMAGE=cloud-notes-api:scout-improved bash scripts/scout-demo.sh quickview`. **Fungsi:** memeriksa artefak hasil perbaikan secara eksplisit. **Baca hasil aktual 8 Oktober 2026:** digest **39d3c08210c2**, **138 paket diindeks**, target dan base **0C/1H/6M/27L**. Ini berkurang dari baseline **0C/4H/9M/28L**, tetapi bukan nol temuan. Label legacy Health score 67%/Policy FAILED masih tampil; 67% bukan persentase aman atau nilai kelas.

| Artefak snapshot | Digest pendek | Paket diindeks | Critical | High | Medium | Low |
|---|---|---:|---:|---:|---:|---:|
| Sebelum update, disimpan pengajar sebagai `scout-before` | c9751e34cb88 | 136 | 0 | 4 | 9 | 28 |
| Setelah update, `scout-improved` | 39d3c08210c2 | 138 | 0 | 1 | 6 | 27 |

**Kunci review tim:** verifikasi perubahan paket serta temuan dari laporan lengkap; penurunan severity total tidak membuktikan semua risiko selesai. Jumlah paket dapat naik ketika dependency berubah meskipun temuan turun. Satu high masih perlu ditinjau dengan advisory, fixed version, fitur yang digunakan, akses, dan mitigasi. Scan yang baik dilengkapi bukti fungsi aplikasi tetap bekerja, metadata artefak, dan keputusan residual risk. Ini pembahasan formatif dengan jawaban lengkap, bukan tugas/penyerahan baru.

<!-- scout-improved-details:start -->

#### Screenshot Scout 8 — temuan high yang masih tersisa

![Temuan high tersisa berada pada paket zlib OS dan belum memiliki fixed version](screenshots/scout/08_remaining_high.jpg)

**Command aktual:** scan target improved ditulis ke file sementara, lalu konteks high dan akhir hasil dibaca setelah command sukses:

```bash
SCOUT_IMAGE=cloud-notes-api:scout-improved bash scripts/scout-demo.sh cves \
  > /tmp/cloudlab05-scout-improved-cves.txt \
  && grep -B 3 -A 12 'HIGH CVE' /tmp/cloudlab05-scout-improved-cves.txt \
  && tail -n 8 /tmp/cloudlab05-scout-improved-cves.txt
```

**Fungsi/cara kerja:** helper tetap menyimpan laporan invocation; redirection juga menyimpan output terminal ke `/tmp` untuk dipilih dengan grep/tail. Operator `&&` mencegah pembacaan berikutnya bila command sebelumnya gagal. **Baca hasil:** paket OS Debian **zlib**, versi **1:1.3.dfsg+really1.3.1-1**, HIGH **CVE-2026-85091**, affected range **>0** dan fixed **not fixed** sesuai hasil Scout. Versi paket Debian mempunyai format epoch/revisi yang tidak disamakan langsung dengan angka versi upstream. Tiga high Starlette pada baseline tidak muncul sebagai high pada artefak improved; high OS ini tetap ada.

**Kunci keputusan:** catat temuan residual beserta digest, tanggal, advisory, fitur/kondisi yang dipakai, serta mitigasi atau rencana tindak lanjut. Jangan memaksakan versi zlib tebakan atau mengklaim update FastAPI memperbaiki OS. Tracker Debian masih mencatat unfixed pada tinjauan ini; konteks affected range perlu membaca catatan distro/upstream, bukan hanya satu baris summary scanner. Kelas dapat meneruskan demo data dummy setelah menjelaskan batas ini; keputusan rilis kerja perlu review risiko tim yang sesuai. [Tracker Debian zlib](https://security-tracker.debian.org/tracker/CVE-2026-85091)

<!-- scout-improved-details:end -->

## 12. Compose: frontend + backend + PostgreSQL

Smoke check contoh tiga layanan dijalankan dari `examples/compose-notes` dengan **`bash scripts/smoke.sh`** setelah `up --wait` selesai. Script menggunakan Python dalam container API, mengirim HTTP ke web/proxy, dan memeriksa sembilan kasus termasuk pembuatan, pembacaan, validasi, serta penghapusan catatan uji miliknya. Hasil aktual Codespaces **9/9 PASS** tersedia bersama penjelasan `request`/`try`/`finally` pada [panduan Compose](COMPOSE_DEMO.md#62-ulangi-pemeriksaan-dengan-smoke-script). Forwarding dan frontend browser tetap diuji secara terpisah.

[Panduan Compose](COMPOSE_DEMO.md) menjalankan contoh terpisah dengan default web **13006**, API **13005**, serta database **5432 hanya di network internal**. Screenshot online menggunakan alternatif **web 13106/API 13105** karena port 13005 sudah dipakai proses lain; tidak ada proses lain yang dihentikan. Panduan memperlihatkan penggantian nilai port dalam `.env`, pilihan Ports, dan command curl yang mengikuti konfigurasi tersebut. Lihat alur config, build/run, status, logs, web, create/read catatan, persistensi setelah down/up, dan cleanup. Port 8000 serta perilaku memori pada API inti tidak berubah. Contoh ini menghubungkan teori Week 05 dengan Lab 06 dan proyek kelompok.

### Penutupan setelah semua show

Setelah semua pengujian selesai, dari `examples/compose-notes` jalankan `docker compose down`. Kembali ke root dengan `cd ../..`, lalu `bash scripts/demo-online.sh stop` bila API memori masih aktif. Selanjutnya buka halaman Codespaces dan pilih **… → Stop codespace** pada lingkungan kelas.

![Codespace benar-benar dihentikan setelah Compose dan Scout selesai](screenshots/compose/08_codespace_stopped.jpg)

*Langkah: github.com/codespaces → menu lingkungan kelas → Stop codespace. Fungsi: mengakhiri penggunaan compute cloud. Baca bukti aktual setelah rangkaian tambahan: banner Codespace redesigned space adventure stopped. Storage masih dihitung selama lingkungan disimpan. Screenshot menunjukkan ada perubahan belum di-commit; Stop menyimpan lingkungan, sedangkan Delete membuang data lokal. Simpan/push kode yang ingin dipertahankan dan backup data penting sebelum Delete; laporan generated dan .env tetap mengikuti kebijakan Git.*
