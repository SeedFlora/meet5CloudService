# Cloud Notes: frontend + backend + PostgreSQL

Contoh pendamping teori Week 05. Browser mengakses Nginx; `/api/*` diteruskan ke FastAPI melalui hostname service `api`; FastAPI membaca/menulis PostgreSQL melalui hostname service `db`. Data catatan benar-benar tersimpan di PostgreSQL, bukan dictionary di memori Python.

Panduan lengkap dengan screenshot dan penjelasan langkah tersedia di [COMPOSE_DEMO.md](../../COMPOSE_DEMO.md).

## Jalankan

Dari root repository:

```sh
cd examples/compose-notes
cp .env.example .env
docker compose up -d --build --wait
docker compose ps
```

PowerShell lokal menggunakan `Copy-Item .env.example .env` sebagai pengganti `cp`. Laptop lokal memerlukan Docker Desktop/Engine; untuk Codespaces cukup browser dan lingkungan Docker repo yang sudah siap.

- Frontend lokal: <http://localhost:13006/>
- API lokal: <http://localhost:13005/health>
- Swagger lokal: <http://localhost:13005/docs>
- Codespaces: gunakan tab **Ports**, buka **13006** untuk web dan **13005** untuk Swagger. Jangan mengetik localhost laptop untuk mengakses cloud. Pertahankan visibility Private.
- Port database 5432 hanya tersedia di jaringan `backend`, tanpa mapping host dan tanpa forward browser.

Port host dapat diubah melalui `API_PORT` dan `WEB_PORT` dalam `.env` sebelum `up`. Nama project default `cloudlab05-compose`; Compose memberi nama container, network, dan volume berdasarkan project itu.

## Observasi dan persistensi

```sh
curl http://localhost:13006/api/health
curl http://localhost:13005/runtime
docker compose exec -T api id -u
docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT id, title, content FROM notes ORDER BY id;"'
```

API berjalan sebagai UID `10001`. Tambahkan catatan lewat frontend, periksa SQL, lalu jalankan:

```sh
docker compose down
docker compose up -d --wait
```

Catatan tetap ada karena named volume `cloudlab05-compose_db_data` dipakai lagi. API/container dapat dibuat ulang tanpa menghapus datanya. `down` menghentikan service dan menghapus container/network, tetapi menjaga named volume. **`docker compose down -v` akan menghapus volume demo beserta catatan**, sehingga bukan langkah berhenti biasa.

## Lingkup demo

`.env.example` berisi credential palsu untuk kelas. Ini aplikasi demo tanpa login pengguna; jangan mengisi data sensitif atau mempublikasikan port untuk pekerjaan produksi. PostgreSQL menerapkan nilai inisialisasi user/password/database hanya saat volume masih kosong; mengganti `.env` saja tidak mereset credential volume yang sudah terisi. Dependency tingkat atas dipin; dependency transitive/base tag dapat berubah, sehingga contoh ini belum merupakan build byte-identik atau jaminan nol CVE.

API menyediakan `GET /health`, `GET /runtime`, `GET /notes`, `GET /notes/{id}`, `POST /notes` (201), dan `DELETE /notes/{id}` (204). Judul/isi kosong ditolak (422), ID yang tidak ada menghasilkan 404, dan database tidak tersedia menghasilkan 503. Query input memakai parameter psycopg.

Referensi resmi: [Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/), [Compose networks](https://docs.docker.com/compose/how-tos/networking/), [PostgreSQL Official Image dan volume versi 17](https://hub.docker.com/_/postgres), [NGINX Official Image](https://hub.docker.com/_/nginx), [psycopg transactions](https://www.psycopg.org/psycopg3/docs/basic/transactions.html).
