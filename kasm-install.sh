#!/usr/bin/env bash
# kasm-install.sh
set -Eeuo pipefail

EMOJI_OK="✅"; EMOJI_RUN="🚀"; EMOJI_INFO="💡"; EMOJI_WARN="⚠️"; EMOJI_SEC="🔐"; EMOJI_LINK="🔗"; EMOJI_BOX="📦"
say() { printf "%b %s\n" "$1" "$2"; }
trap 'code=$?; say "⚠️" "Error (exit $code) while running: ${BASH_COMMAND:-?}"; exit $code' ERR

# Use sudo if not root
if [[ $EUID -ne 0 ]]; then SUDO="sudo"; else SUDO=""; fi
command -v sudo >/dev/null 2>&1 || { [[ $EUID -eq 0 ]] || { echo "Please run as root or install sudo."; exit 1; }; }

# Safe password generator (locale-proof, no tr range pitfalls)
gen_pw() {
  local p
  for _ in {1..20}; do
    if command -v openssl >/dev/null 2>&1; then
      LC_ALL=C p="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9!@#$%^&*_.+=-' | head -c 20 || true)"
    else
      LC_ALL=C p="$(tr -dc 'A-Za-z0-9!@#$%^&*_.+=-' </dev/urandom | head -c 20 || true)"
    fi
    [[ -n "${p:-}" ]] || continue
    if [[ ${#p} -ge 12 && "$p" =~ [A-Z] && "$p" =~ [a-z] && "$p" =~ [0-9] && "$p" =~ [\!\@\#\$\%\^\&\*\_\.\+\=\-] ]]; then
      echo "$p"; return
    fi
  done
  echo "Aa1!$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)"
}

ADMIN_PW="${ADMIN_PW:-$(gen_pw)}"
USER_PW="${USER_PW:-$(gen_pw)}"

# IPs / URLs
PRIVATE_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
PUBLIC_IP="$(curl -fsS --max-time 4 https://ifconfig.me 2>/dev/null || true)"
ACCESS_URL="https://${PRIVATE_IP:-localhost}"

say "$EMOJI_BOX" "Downloading & installing Kasm Workspaces 1.17.0 …"
cd /tmp
curl -fsSL -o kasm_release.tar.gz "https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.7f020d.tar.gz"
tar -xf kasm_release.tar.gz

$SUDO bash kasm_release/install.sh \
  --accept-eula \
  --admin-password "$ADMIN_PW" \
  --user-password "$USER_PW"

# Open 443 if UFW active
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  $SUDO ufw allow 443/tcp || true
fi

say "$EMOJI_OK" "Kasm installed."
say "$EMOJI_LINK" "Open (LAN): ${ACCESS_URL}"
[[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "$PRIVATE_IP" ]] && say "$EMOJI_LINK" "Open (Public, if routed): https://${PUBLIC_IP}"

say "$EMOJI_SEC" "Credentials:"
printf "    %-20s %s\n" "Admin user" "admin@kasm.local"
printf "    %-20s %s\n" "Admin pass" "$ADMIN_PW"
printf "    %-20s %s\n" "User  user" "user@kasm.local"
printf "    %-20s %s\n" "User  pass" "$USER_PW"

CREDS_FILE="${HOME}/kasm_credentials.txt"
{
  echo "Kasm URL (LAN): ${ACCESS_URL}"
  [[ -n "$PUBLIC_IP" ]] && echo "Kasm URL (Public): https://${PUBLIC_IP}"
  echo "Admin: admin@kasm.local / ${ADMIN_PW}"
  echo "User : user@kasm.local  / ${USER_PW}"
} > "$CREDS_FILE"
say "$EMOJI_INFO" "Saved to: $CREDS_FILE"
say "$EMOJI_OK" "Done 🎉"
