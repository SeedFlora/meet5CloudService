#!/usr/bin/env bash
# Demo kelas: Docker berjalan di mesin Linux cloud, browser menjadi jendela kendali.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="cloudlab-theory-online"
IMAGE_NAME="cloud-notes-api:theory-online"
LABEL_KEY="edu.binus.cloud-services.demo"
LABEL_VALUE="week05-online"
DEMO_PORT="${DEMO_PORT:-8000}"
BASE_URL="http://127.0.0.1:${DEMO_PORT}"

fail() { printf 'GAGAL: %s\n' "$*" >&2; exit 1; }
info() { printf '\n== %s ==\n' "$*"; }

usage() {
  cat <<'HELP'
Demo Docker teori minggu 5 — tidak ada tugas terpisah.
Jalankan dari terminal Linux Codespaces / Killercoda:
  bash scripts/demo-online.sh check
  bash scripts/demo-online.sh build
  bash scripts/demo-online.sh start
  bash scripts/demo-online.sh status
  bash scripts/demo-online.sh test
  bash scripts/demo-online.sh test --restart
  bash scripts/demo-online.sh stop

check  : periksa Docker client, daemon, dan curl.
build  : build Dockerfile asli Lab 05 menjadi image.
start  : build dan buat container jika belum ada; gunakan ulang container demo sendiri.
status : lihat container, port, log, dan user runtime.
test   : uji HTTP 200 / 201 / 422 / 404 dan Swagger.
--restart : tambahan demonstrasi; restart menghapus SEMUA catatan in-memory demo.
stop   : hapus hanya container berlabel demo ini; image dan container lain tetap ada.

Port alternatif: DEMO_PORT=18005 bash scripts/demo-online.sh start
Gunakan nilai DEMO_PORT yang sama pada status/test/stop berikutnya.
Sesudah mengubah kode: stop, lalu start untuk membuat container dari image baru.
HELP
}

validate_port() {
  [[ "$DEMO_PORT" =~ ^[1-9][0-9]{0,4}$ ]] || fail 'DEMO_PORT harus angka 1–65535 tanpa nol di depan.'
  (( 10#$DEMO_PORT <= 65535 )) || fail 'DEMO_PORT melebihi 65535.'
}

check_tools() {
  command -v docker >/dev/null 2>&1 || fail 'Docker CLI belum tersedia. Gunakan Codespaces dengan konfigurasi repo ini atau playground Docker.'
  command -v curl >/dev/null 2>&1 || fail 'curl belum tersedia pada terminal Linux ini.'
  docker info >/dev/null 2>&1 || fail 'Docker daemon belum siap. Tunggu inisialisasi Codespaces; periksa docker version.'
}

container_exists() { docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; }

require_owned() {
  local actual_label
  actual_label="$(docker container inspect --format "{{ index .Config.Labels \"${LABEL_KEY}\" }}" "$CONTAINER_NAME")"
  [[ "$actual_label" == "$LABEL_VALUE" ]] || fail "Nama ${CONTAINER_NAME} dipakai container lain. Script menolak mengubah atau menghapusnya."
}

require_matching_port() {
  local actual_mapping
  actual_mapping="$(docker port "$CONTAINER_NAME" 8000/tcp 2>/dev/null || true)"
  [[ "$actual_mapping" == *":${DEMO_PORT}"* ]] || fail "Port container berbeda dari DEMO_PORT=${DEMO_PORT}. Periksa docker port ${CONTAINER_NAME}."
}

require_running() {
  container_exists || fail 'Container belum ada. Jalankan start dahulu.'
  require_owned
  [[ "$(docker container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" == 'true' ]] || fail 'Container belum berjalan. Jalankan start dahulu.'
  require_matching_port
}

wait_ready() {
  local attempt
  for attempt in {1..30}; do
    if curl --silent --fail --connect-timeout 1 --max-time 2 "${BASE_URL}/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  docker logs --tail 30 "$CONTAINER_NAME" >&2
  fail "API tidak siap di ${BASE_URL} setelah 30 percobaan."
}

build_image() {
  info 'Dockerfile (resep) → image (paket aplikasi)'
  docker build --tag "$IMAGE_NAME" "$ROOT_DIR"
}

start_container() {
  if container_exists; then
    require_owned
    if [[ "$(docker container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" != 'true' ]]; then
      docker start "$CONTAINER_NAME"
    fi
    require_matching_port
    printf 'Container demo dipakai ulang. Untuk menerapkan perubahan kode: stop, lalu start.\n'
  else
    build_image
    info 'Image → container berjalan; port mesin cloud → port aplikasi'
    docker run --detach --name "$CONTAINER_NAME" \
      --label "${LABEL_KEY}=${LABEL_VALUE}" \
      --publish "${DEMO_PORT}:8000" \
      --env APP_ENV=classroom \
      "$IMAGE_NAME"
  fi
  wait_ready
  printf 'API siap: %s/health\nSwagger: %s/docs\n' "$BASE_URL" "$BASE_URL"
  printf 'Di browser Codespaces gunakan tab Ports → port %s → Open in Browser → /docs.\n' "$DEMO_PORT"
}

show_status() {
  info 'Status container dan image'
  if ! container_exists; then
    printf 'Container demo belum dibuat atau sudah dihentikan dan dihapus.\n'
    return 0
  fi
  require_owned
  docker ps --all --filter "name=^/${CONTAINER_NAME}$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  if [[ "$(docker container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" == 'true' ]]; then
    printf '\nUser proses aplikasi (bukan root):\n'
    docker exec "$CONTAINER_NAME" id
  fi
  printf '\nLog terbaru:\n'
  docker logs --tail 8 "$CONTAINER_NAME"
}

# Pisahkan HTTP status terakhir dari body tanpa membutuhkan jq atau Python host.
request() {
  local method="$1" path="$2" expected="$3" payload="${4-}" response
  if [[ "$method" == 'POST' ]]; then
    response="$(curl --silent --show-error --connect-timeout 2 --max-time 10 \
      --request POST --header 'Content-Type: application/json' --data "$payload" \
      --write-out $'\n%{http_code}' "${BASE_URL}${path}")"
  else
    response="$(curl --silent --show-error --connect-timeout 2 --max-time 10 \
      --write-out $'\n%{http_code}' "${BASE_URL}${path}")"
  fi
  HTTP_STATUS="${response##*$'\n'}"
  HTTP_BODY="${response%$'\n'*}"
  [[ "$HTTP_STATUS" == "$expected" ]] || fail "${method} ${path}: HTTP ${HTTP_STATUS}; diharapkan ${expected}. Body: ${HTTP_BODY}"
  printf 'PASS %s %s → HTTP %s\n' "$method" "$path" "$HTTP_STATUS"
  if [[ "$path" != '/docs' ]]; then printf '%s\n' "$HTTP_BODY"; fi
}

test_api() {
  local option="${1-}" note_id
  [[ -z "$option" || "$option" == '--restart' ]] || fail 'Pilihan test yang tersedia hanya --restart.'
  require_running
  wait_ready
  info 'HTTP: layanan hidup, konfigurasi runtime, validasi, data, dokumentasi'
  request GET /health 200
  [[ "$HTTP_BODY" == *'"status":"ok"'* && "$HTTP_BODY" == *'"service":"cloud-notes-api"'* ]] || fail 'Isi /health tidak sesuai aplikasi demo.'
  request GET /runtime 200
  [[ "$HTTP_BODY" == *'"environment":"classroom"'* && "$HTTP_BODY" == *'"storage":"memory"'* ]] || fail 'APP_ENV atau jenis penyimpanan tidak sesuai.'
  request POST /notes 201 '{"title":"Demo Docker teori","content":"Resep → image → container; data sementara di memori."}'
  [[ "$HTTP_BODY" =~ \"id\":[[:space:]]*([0-9]+) ]] || fail 'POST tidak menghasilkan id catatan.'
  note_id="${BASH_REMATCH[1]}"
  request GET "/notes/${note_id}" 200
  [[ "$HTTP_BODY" == *'Demo Docker teori'* ]] || fail 'Catatan yang dibuat tidak ditemukan.'
  request GET /notes 200
  request POST /notes 422 '{"title":"   ","content":"contoh invalid"}'
  request GET /notes/0 404
  request GET /docs 200
  if [[ "$option" == '--restart' ]]; then
    info 'Restart proses: catatan in-memory menghilang (bukan penyimpanan database)'
    docker restart "$CONTAINER_NAME"
    wait_ready
    request GET /notes 200
    [[ "$HTTP_BODY" == '[]' ]] || fail 'Daftar catatan seharusnya kosong sesudah restart proses.'
    printf 'PASS: data sementara hilang sesudah restart. Volume saja tidak mengubah dict Python menjadi database.\n'
  fi
  printf '\nSemua pemeriksaan demo lulus. Ini demonstrasi formatif, tanpa tugas atau nilai lab terpisah.\n'
}

stop_container() {
  info 'Bersihkan hanya container milik demo ini'
  if ! container_exists; then
    printf 'Container demo sudah tidak ada.\n'
    return 0
  fi
  require_owned
  docker rm --force "$CONTAINER_NAME"
  printf 'Container demo dihapus; image tetap tersimpan. Catatan in-memory demo ikut hilang.\n'
}

action="${1:-help}"
case "$action" in
  help|-h|--help) usage; exit 0 ;;
  check|build|start|status|test|stop) ;;
  *) usage; fail "Perintah tidak dikenal: ${action}" ;;
esac
(( $# <= 2 )) || fail 'Terlalu banyak argumen.'
if [[ "$action" != 'test' && $# -gt 1 ]]; then fail 'Argumen kedua hanya dipakai untuk test --restart.'; fi
validate_port
check_tools
case "$action" in
  check) info 'Docker client dan daemon tersedia'; docker version; curl --version | head -n 1 ;;
  build) build_image ;;
  start) start_container ;;
  status) show_status ;;
  test) test_api "${2-}" ;;
  stop) stop_container ;;
esac
