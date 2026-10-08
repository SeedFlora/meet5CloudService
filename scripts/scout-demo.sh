#!/usr/bin/env bash
# Docker Scout classroom wrapper. Sources verified on 2026-10-08:
# https://github.com/docker/scout-cli/releases/tag/v1.26.0
# https://github.com/docker/scout-cli/releases/expanded_assets/v1.26.0
# https://docs.docker.com/scout/install/
# https://docs.docker.com/reference/cli/docker/scout/cves/
set -euo pipefail
umask 077

readonly SCOUT_VERSION='1.26.0'
readonly RELEASE_BASE="https://github.com/docker/scout-cli/releases/download/v${SCOUT_VERSION}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCOUT_IMAGE="${SCOUT_IMAGE:-cloud-notes-api:theory-online}"
CACHE_ROOT="${XDG_CACHE_HOME:-${HOME}/.cache}/cloud-services-scout"
CACHE_DIR=''
SCOUT_BINARY=''
EXPECTED_ARCHIVE_SHA=''
ARCH=''
REPORT_DIR=''
INSTALL_TEMP_DIR=''

info() { printf '\n== %s ==\n' "$*"; }
fail() { printf 'GAGAL: %s\n' "$*" >&2; exit 1; }

cleanup_install() {
  if [[ -n "$INSTALL_TEMP_DIR" ]]; then
    rm -f -- "${INSTALL_TEMP_DIR}/archive.tar.gz" "${INSTALL_TEMP_DIR}/docker-scout"
    rmdir -- "$INSTALL_TEMP_DIR" 2>/dev/null || true
  fi
}

usage() {
  cat <<'HELP'
Docker Scout opsional untuk teori minggu 5 (Linux Codespaces).
  bash scripts/scout-demo.sh install
  bash scripts/scout-demo.sh check
  bash scripts/scout-demo.sh quickview
  bash scripts/scout-demo.sh cves
  bash scripts/scout-demo.sh recommendations
  bash scripts/scout-demo.sh report

install         Ambil binary official v1.26.0, verifikasi SHA256, simpan di cache user.
check           Periksa binary pinned, daemon Docker, dan image lokal (bukan bukti login).
quickview       Ringkasan kerentanan image + base image dari layanan Scout.
cves            Detail CVE menurut paket, severity, dan versi perbaikan.
recommendations Saran refresh/update base image; tidak otomatis mengganti Dockerfile.
report          Semua laporan teks dan SARIF; berhenti jika layanan gagal diakses.

Default image: cloud-notes-api:theory-online
Image lain: SCOUT_IMAGE=nama:tag bash scripts/scout-demo.sh quickview
Build image terlebih dahulu: bash scripts/demo-online.sh build

Binary standalone berjalan di cloud, bukan laptop; tidak mengubah plugin Docker lain.
Scan memakai local:// agar image tidak diambil dari registry secara tidak sengaja.
Local image tetap membutuhkan layanan Scout online, akun Docker/entitlement yang valid.
Script tidak menjalankan login, enroll, repo enable, push, pembayaran, atau cleanup Docker.
Jika diminta autentikasi, pengguna melakukan login Docker sendiri di luar script.
Tidak tampilkan password/PAT, Docker config, atau command login ketika merekam kelas.

Laporan disimpan di hasil/scout/<waktu-UTC>-<acak>/ dan diabaikan Git secara otomatis.
Hasil berbeda menurut digest image, platform, tanggal, dan basis data advisory.
Exit 0 berarti command selesai, bukan jaminan image bebas kerentanan atau aman produksi.
HELP
}

platform() {
  [[ "$(uname -s)" == 'Linux' ]] || fail 'Installer ini untuk Linux Codespaces/playground. Di Windows/macOS gunakan Docker Desktop Scout atau Codespaces.'
  case "$(uname -m)" in
    x86_64|amd64)
      ARCH='amd64'
      EXPECTED_ARCHIVE_SHA='47daa9ac442816316c65389f516b847146bb9f45e8d6afdcbb9ce835c4e138bd'
      ;;
    aarch64|arm64)
      ARCH='arm64'
      EXPECTED_ARCHIVE_SHA='34282a50d6787eec46e44a377a1ed9e70342adf078135cca8617c9199852725c'
      ;;
    *) fail 'Platform Linux didukung hanya amd64 dan arm64 pada release pinned ini.' ;;
  esac
  CACHE_DIR="${CACHE_ROOT}/${SCOUT_VERSION}/${ARCH}"
  SCOUT_BINARY="${CACHE_DIR}/docker-scout"
}

validate_image() {
  [[ "$SCOUT_IMAGE" =~ ^[[:alnum:]][[:alnum:]._/@:+-]*$ ]] || fail 'SCOUT_IMAGE harus nama/tag/digest image, tanpa spasi atau flag command.'
}

verify_cached_binary() {
  [[ -x "$SCOUT_BINARY" && ! -L "$SCOUT_BINARY" ]] || fail 'Binary Scout pinned belum tersedia. Jalankan install terlebih dahulu.'
  [[ -f "${CACHE_DIR}/owner.txt" && ! -L "${CACHE_DIR}/owner.txt" ]] || fail 'Cache binary bukan instalasi wrapper ini; script menolak memakai/mengganti file tersebut.'
  [[ "$(cat "${CACHE_DIR}/owner.txt")" == "cloud-services-scout ${SCOUT_VERSION} ${ARCH} ${EXPECTED_ARCHIVE_SHA}" ]] || fail 'Marker cache Scout tidak sesuai release pinned.'
  [[ -f "${CACHE_DIR}/binary.sha256" && ! -L "${CACHE_DIR}/binary.sha256" ]] || fail 'Checksum binary cache hilang.'
  (cd -- "$CACHE_DIR" && sha256sum --check binary.sha256 >/dev/null) || fail 'Binary cache berubah; periksa cache sebelum memasang ulang.'
}

install_scout() {
  local prerequisite temp_dir archive_name binary_sha version_text
  for prerequisite in curl tar sha256sum install mktemp; do
    command -v "$prerequisite" >/dev/null 2>&1 || fail "Prasyarat installer belum tersedia: ${prerequisite}."
  done
  if [[ -e "$SCOUT_BINARY" || -L "$SCOUT_BINARY" ]]; then
    verify_cached_binary
    printf 'Binary pinned sudah tersedia dan checksum cache valid.\n'
    "$SCOUT_BINARY" version
    return 0
  fi
  [[ ! -L "$CACHE_ROOT" && ! -L "${CACHE_ROOT}/${SCOUT_VERSION}" && ! -L "$CACHE_DIR" ]] || fail 'Direktori cache adalah symlink; instalasi dibatalkan.'
  if [[ -e "${CACHE_DIR}/owner.txt" || -e "${CACHE_DIR}/binary.sha256" ]]; then
    fail 'Cache instalasi tidak lengkap; periksa file cache sebelum memasang ulang.'
  fi
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/cloudlab-scout-install.XXXXXX")"
  INSTALL_TEMP_DIR="$temp_dir"
  # Only these two exact files are removed, never a recursive user-directory delete.
  trap cleanup_install EXIT
  archive_name="docker-scout_${SCOUT_VERSION}_linux_${ARCH}.tar.gz"
  info "Unduh official Docker Scout ${SCOUT_VERSION} linux/${ARCH}"
  curl --fail --location --silent --show-error --retry 2 \
    --connect-timeout 15 --max-time 180 --proto '=https' --proto-redir '=https' --tlsv1.2 \
    "${RELEASE_BASE}/${archive_name}" --output "${temp_dir}/archive.tar.gz"
  printf '%s  %s\n' "$EXPECTED_ARCHIVE_SHA" "${temp_dir}/archive.tar.gz" | sha256sum --check -
  tar --extract --gzip --file "${temp_dir}/archive.tar.gz" --directory "$temp_dir" docker-scout
  [[ -f "${temp_dir}/docker-scout" && ! -L "${temp_dir}/docker-scout" ]] || fail 'Archive tidak menghasilkan binary file yang diharapkan.'
  chmod 0755 "${temp_dir}/docker-scout"
  version_text="$("${temp_dir}/docker-scout" version)"
  [[ "$version_text" == *"${SCOUT_VERSION}"* ]] || fail 'Versi binary berbeda dari release pinned.'
  binary_sha="$(sha256sum "${temp_dir}/docker-scout")"
  binary_sha="${binary_sha%% *}"
  mkdir -p -- "$CACHE_DIR"
  install -m 0755 "${temp_dir}/docker-scout" "$SCOUT_BINARY"
  printf 'cloud-services-scout %s %s %s\n' "$SCOUT_VERSION" "$ARCH" "$EXPECTED_ARCHIVE_SHA" > "${CACHE_DIR}/owner.txt"
  printf '%s  docker-scout\n' "$binary_sha" > "${CACHE_DIR}/binary.sha256"
  verify_cached_binary
  printf '%s\n' "$version_text"
  printf 'Binary standalone: %s\nPlugin Docker/config login tidak diubah.\n' "$SCOUT_BINARY"
}

technical_prerequisites() {
  command -v docker >/dev/null 2>&1 || fail 'Docker CLI belum tersedia.'
  command -v sha256sum >/dev/null 2>&1 || fail 'sha256sum diperlukan untuk memeriksa binary cache.'
  verify_cached_binary
  docker info --format '{{.ServerVersion}}' >/dev/null 2>&1 || fail 'Daemon Docker belum siap.'
  docker image inspect "$SCOUT_IMAGE" --format '{{.Id}}' >/dev/null 2>&1 || fail "Image lokal ${SCOUT_IMAGE} tidak tersedia; build dahulu. Script tidak melakukan pull otomatis."
}

check_scout() {
  info 'Prasyarat teknis Scout dan image lokal'
  "$SCOUT_BINARY" version
  printf 'Daemon Docker: '
  docker info --format '{{.ServerVersion}}'
  docker image inspect "$SCOUT_IMAGE" --format 'Docker image ID: {{.Id}} | Platform: {{.Os}}/{{.Architecture}}'
  printf 'Prasyarat teknis siap. Autentikasi/akses layanan Scout belum diuji oleh check.\n'
  printf 'Jalankan quickview untuk memeriksa akses layanan dan hasil aktual.\n'
}

new_report() {
  local results_root="${ROOT_DIR}/hasil/scout"
  [[ ! -L "$results_root" ]] || fail 'Folder hasil/scout adalah symlink; script menolak menulis laporan.'
  mkdir -p -- "$results_root"
  if [[ ! -e "${results_root}/.gitignore" ]]; then
    printf '*\n' > "${results_root}/.gitignore"
  fi
  REPORT_DIR="$(mktemp -d "${results_root}/$(date -u '+%Y%m%dT%H%M%SZ')-XXXXXX")"
  {
    printf 'Generated UTC: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'Scout release: %s\nImage reference: %s\nSource: local image store (local://)\n' "$SCOUT_VERSION" "$SCOUT_IMAGE"
    docker image inspect "$SCOUT_IMAGE" --format 'Docker image ID: {{.Id}}{{println}}Image platform: {{.Os}}/{{.Architecture}}{{println}}Repo digests: {{json .RepoDigests}}'
    printf 'Docker image ID semantics depend on the image store; retain Scout target digest and platform when comparing scans.\n'
    printf 'No automatic login, enrollment, image publishing, or Docker cleanup.\n'
    printf 'Reports may be partial if authentication, entitlement, or network fails.\n'
  } > "${REPORT_DIR}/metadata.txt"
  printf 'Laporan lokal: %s\n' "$REPORT_DIR"
}

capture_scan() {
  local action="$1" filename="$2"
  shift 2
  local -a statuses
  info "Scout ${action}: local://${SCOUT_IMAGE}"
  set +e
  "$SCOUT_BINARY" "$action" "$@" "local://${SCOUT_IMAGE}" < /dev/null 2>&1 | tee "${REPORT_DIR}/${filename}"
  statuses=("${PIPESTATUS[@]}")
  set -e
  printf '%s\n' "${statuses[0]}" > "${REPORT_DIR}/${filename}.exitcode.txt"
  if [[ "${statuses[1]}" -ne 0 ]]; then
    printf 'GAGAL: Tidak dapat menulis output laporan.\n' >&2
    return 1
  fi
  if [[ "${statuses[0]}" -ne 0 ]]; then
    printf 'Command Scout gagal (exit %s); ini BUKAN hasil nol CVE.\n' "${statuses[0]}" >&2
    printf 'Periksa pesan layanan: login Docker oleh pengguna, entitlement/kuota, atau jaringan.\nScript tidak melakukan login otomatis.\n' >&2
    printf 'INCOMPLETE: %s returned %s. Other reports may not have run.\n' "$action" "${statuses[0]}" >> "${REPORT_DIR}/metadata.txt"
    return "${statuses[0]}"
  fi
}

scan_report() {
  local action="$1"
  new_report
  case "$action" in
    quickview) capture_scan quickview quickview.txt ;;
    cves) capture_scan cves cves.txt ;;
    recommendations) capture_scan recommendations recommendations.txt ;;
    report)
      capture_scan quickview quickview.txt
      capture_scan cves cves.txt
      capture_scan recommendations recommendations.txt
      capture_scan cves cves-sarif.console.txt --format sarif --output "${REPORT_DIR}/cves.sarif.json"
      [[ -s "${REPORT_DIR}/cves.sarif.json" ]] || fail 'Scout tidak menghasilkan file SARIF; laporan belum lengkap.'
      ;;
  esac
  printf 'COMPLETE: requested command finished; not a zero-vulnerability guarantee.\n' >> "${REPORT_DIR}/metadata.txt"
  printf '\nSelesai. Baca output actual pada %s\n' "$REPORT_DIR"
}

action="${1:-help}"
case "$action" in
  help|-h|--help) usage; exit 0 ;;
  install|check|quickview|cves|recommendations|report) ;;
  *) usage; fail "Perintah tidak dikenal: ${action}" ;;
esac
[[ $# -eq 1 ]] || fail 'Gunakan satu perintah; pilih image melalui SCOUT_IMAGE.'
platform
validate_image
if [[ "$action" == 'install' ]]; then
  install_scout
else
  technical_prerequisites
  if [[ "$action" == 'check' ]]; then check_scout; else scan_report "$action"; fi
fi
