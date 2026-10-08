# Sumber foto perumpamaan Docker — Pertemuan 05

Foto berikut dipakai sebagai ilustrasi restoran pada PPT teori. Foto tidak menggambarkan hasil pengujian Docker. Screenshot demo merupakan tangkapan langsung Codespaces dan Swagger; command serta hasilnya dijelaskan pada PPT dan `DEMO_ONLINE.md`.

| Perumpamaan | Foto dan pembuat |
|---|---|
| Dockerfile sebagai resep | [Cozy Kitchen Setup with Cookbook and Pot — Daniel & Hannah Snipes](https://www.pexels.com/photo/cozy-kitchen-setup-with-cookbook-and-pot-29834258/) |
| RUN saat persiapan, CMD saat layanan mulai | [Chef Chopping Food on a Cutting Board — Mateusz Feliksik](https://www.pexels.com/photo/chef-chopping-food-on-a-cutting-board-13422410/) |
| EXPOSE dan mapping port sebagai nomor loket/jalur masuk | [Counter in a Restaurant — Nam Quân Nguyễn](https://www.pexels.com/photo/counter-in-a-restaurant-15650131/) |
| Cache sebagai bahan yang telah disiapkan | [Fresh Vegetables in Bowl Next to Diced Squid — Rachel Claire](https://www.pexels.com/photo/fresh-vegetables-in-bowl-next-to-diced-squid-5863647/) |
| Builder/runtime memilih isi paket | [Food in Take Out Containers — FOX](https://www.pexels.com/photo/food-in-take-out-containers-10748605/) |

Foto dipakai sesuai [Pexels License](https://www.pexels.com/license/), diperiksa 8 Oktober 2026. Foto pihak ketiga mengikuti lisensi sumber tersebut; lisensi MIT kode repo tidak mengalihkan hak atas foto. Kredit dan URL juga ada pada speaker notes slide terkait. Foto asli tidak disediakan sebagai galeri unduhan terpisah.

## Sumber konsep

- [Docker image](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/), [container](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/), dan [Dockerfile reference](https://docs.docker.com/reference/dockerfile/).
- [Publishing ports](https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/), [cache optimization](https://docs.docker.com/build/cache/optimize/), [multi-stage builds](https://docs.docker.com/build/building/multi-stage/).
- [GitHub Codespaces](https://docs.github.com/en/codespaces/quickstart) dan [port forwarding](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

## Docker Scout: konsep dan sumber teknis

Perumpamaan tambahan dibuat untuk pengajaran: SBOM seperti daftar bahan beserta nomor batch, Scout mencocokkannya dengan advisory atau daftar recall, dan perubahan bahan perlu diikuti rebuild serta pengujian. Perumpamaan bukan definisi resmi dan tidak menyatakan scan sebagai jaminan keamanan.

- [Docker Scout](https://docs.docker.com/scout/) dan [image analysis](https://docs.docker.com/scout/explore/analysis/): komponen software, advisory, dan batas analisis.
- [Install Scout](https://docs.docker.com/scout/install/), [quickstart](https://docs.docker.com/scout/quickstart/), dan [CLI configuration](https://docs.docker.com/scout/how-tos/configure-cli/): plugin, autentikasi, dan kebutuhan jaringan.
- [Quickview](https://docs.docker.com/reference/cli/docker/scout/quickview/), [CVEs](https://docs.docker.com/reference/cli/docker/scout/cves/), dan [recommendations](https://docs.docker.com/reference/cli/docker/scout/recommendations/): arti command dan cara membaca hasil.
- [Retired products and features](https://docs.docker.com/retired/): demo menggunakan CLI aktif yang dirujuk di atas; health scores/Scout Everywhere dan fitur notifikasi/Policies dashboard yang retired tidak dijadikan alur kelas.
- Advisory primer untuk meninjau contoh CVE pada screenshot: [Starlette form parsing](https://github.com/Kludex/starlette/security/advisories/GHSA-82w8-qh3p-5jfq), [Starlette StaticFiles Windows](https://github.com/Kludex/starlette/security/advisories/GHSA-wqp7-x3pw-xc5r), dan [Debian tracker zlib CVE-2026-85091](https://security-tracker.debian.org/tracker/CVE-2026-85091). Versi paket terdeteksi perlu ditinjau bersama fitur/platform yang digunakan aplikasi.

<!-- scout-screenshot-provenance:start -->

Screenshot Scout diambil langsung dari terminal Chrome/Codespaces **8 Oktober 2026**, CLI standalone **1.26.0**, target `local://cloud-notes-api:theory-online`, platform Linux/amd64, image ID/digest pendek `c9751e34cb88`. Analisis berjalan menggunakan akses yang tersedia pada Codespace tersebut; tidak ada klaim bahwa seluruh lingkungan dapat scan tanpa akun. Tidak ada kredensial yang dicetak atau dipindahkan untuk materi.

| Berkas dalam `screenshots/scout/` | Langkah/bukti |
|---|---|
| `01_install_check.jpg` | Binary/daemon/image lokal siap; check belum menguji akses layanan. |
| `02_quickview.jpg` | Scan berhasil: target 0C/4H/9M/28L, 136 paket diindeks, base teridentifikasi. Health/policy legacy yang tampil bukan persentase keamanan/nilai kelas. |
| `03_cves.jpg` | 41 temuan pada 15 paket; contoh nyata paket shadow/apt severity LOW dengan fixed version not fixed. |
| `03b_high_packages.jpg` | Cuplikan high tersimpan: Starlette memiliki kandidat fix per advisory; zlib not fixed. Baseline sebelum pembaruan dependency; wildcard dapat membaca beberapa laporan. |
| `03c_starlette_example.jpg` | Versi terpasang 0.46.2, affected range dan fixed version dari dua advisory Starlette pada satu laporan baseline eksplisit. |
| `04_recommendations.jpg` | Base python:3.12-slim/runtime 3.12.15 up to date, tidak ada alternatif tag pada hasil itu; bukan bukti tidak ada risiko. |
| `05_report.jpg` | Ekspor SARIF berhasil ditulis, 41 temuan/15 paket; hasil generated lokal diabaikan Git. |
| `06_improved_tests.jpg` | API setelah pembaruan dependency lulus HTTP/reset memori; versi dalam container FastAPI 0.142.4/Starlette 1.7.0/Uvicorn 0.54.0, lalu tag scout-improved. |
| `07_improved_quickview.jpg` | Tag scout-improved, digest 39d3c08210c2, 138 paket, 0C/1H/6M/27L; legacy 67% bukan persentase keamanan. |
| `08_remaining_high.jpg` | Scan improved, rincian high residual zlib versi Debian/not fixed; Python dependency update tidak membuktikan OS diperbaiki. |

Baseline sebelum update digest `c9751e34cb88` disimpan pengajar dengan tag `cloud-notes-api:scout-before` sebelum source dibuild ulang. Image `cloud-notes-api:theory-online` setelah rebuild juga diberi tag lokal `cloud-notes-api:scout-improved`, digest `39d3c08210c2`. Tag nama dapat digunakan ulang; perbandingan memakai digest/platform/waktu serta versi paket. Screenshot baru merupakan bukti fungsi dan scan hasil perubahan, tanpa mengklaim seluruh risiko selesai.

Command, arti hasil, batas analisis, dan kunci keputusan ada pada [demo online](../DEMO_ONLINE.md#11-docker-scout-opsional-510-menit) dan [modul mahasiswa](../MODUL_MAHASISWA.md). Hasil ini snapshot, bukan jumlah yang diharuskan pada image/tag lain atau waktu advisory berbeda.

<!-- scout-screenshot-provenance:end -->

## Compose: sumber teknis dan bukti

- [Compose application model](https://docs.docker.com/compose/intro/compose-application-model/), [networking](https://docs.docker.com/compose/how-tos/networking/), dan [startup order](https://docs.docker.com/compose/how-tos/startup-order/): service, DNS internal, dan kesiapan dependency.
- [Compose up](https://docs.docker.com/reference/cli/docker/compose/up/), [Compose down](https://docs.docker.com/reference/cli/docker/compose/down/), dan [volumes](https://docs.docker.com/engine/storage/volumes/): build/run, cleanup, dan persistensi.

<!-- compose-screenshot-provenance:start -->

Screenshot diambil dari Chrome/Codespaces dan frontend aktual pada **8 Oktober 2026**. Kode: `examples/compose-notes`. Target project `cloudlab05-compose`; port host alternatif API **13105**, web **13106**, PostgreSQL 5432 hanya pada network internal. Default repo tetap API 13005/web 13006. Data handover merupakan data dummy kelas.

| Berkas dalam `screenshots/compose/` | Langkah/bukti |
|---|---|
| `01_config.jpg` | Config quiet, nama service, dan versi Compose; bukan bukti aplikasi berjalan. |
| `02_up.jpg` | Build API/web dan startup db/api/web hingga healthy. |
| `03_ps.jpg` | Status, port mapping, UID 10001, dan health yang memeriksa PostgreSQL. |
| `03b_logs_dns.jpg` | Log layanan, lookup db dari API, dan query DNS absolut `api.` dari web. IP bersifat sementara. |
| `03c_ports.jpg` | Forwarding port alternatif melalui Codespaces, visibility Private. |
| `04_web.jpg` | Frontend awal dan koneksi API/database. |
| `05_note_saved.jpg` | Catatan dummy dibuat pada browser dan daftar dibaca dari backend. |
| `05b_database.jpg` | SQL PostgreSQL dan JSON melalui web/proxy memuat ID/judul catatan yang sama; Python dijalankan di container API. |
| `05c_http_tests.jpg` | Smoke script aktual 9/9 HTTP PASS, menguji input/ID error yang sengaja diharapkan dan hanya menghapus catatan sementara. |
| `06_persistence.jpg` | Down menghapus container/network, volume tetap ada, up healthy, lalu JSON tetap memuat handover ID 1. |
| `06b_persistence_web.jpg` | Frontend dimuat ulang setelah recreate dan tetap menampilkan handover ID 1. |
| `07_down.jpg` | Cleanup, ps kosong, dan named volume tetap tersedia. Compute Codespaces belum dihentikan oleh down. |
| `08_codespace_stopped.jpg` | Konfirmasi GitHub bahwa Codespace kelas stopped sesudah semua demo; compute berhenti, storage dan perubahan lokal masih ada. |

Command, fungsi, cara kerja, dan batas bukti dijelaskan pada [panduan Compose](../COMPOSE_DEMO.md). Screenshot merupakan bukti runtime; foto restoran tetap hanya ilustrasi konsep.

<!-- compose-screenshot-provenance:end -->
