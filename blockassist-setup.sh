#!/usr/bin/env bash
# blockassist-setup.sh — installs BlockAssist, fixes JAVA_HOME, pyenv+Python, and creates a one-shot launcher (no auto-restart)
set -Eeuo pipefail

EMOJI_OK="✅"; EMOJI_RUN="🚀"; EMOJI_INFO="💡"; EMOJI_WARN="⚠️"; EMOJI_GEAR="🛠️"; EMOJI_BOX="📦"
say(){ printf "%b %s\n" "$1" "$2"; }
trap 'c=$?; say "⚠️" "Error (exit $c) while running: ${BASH_COMMAND:-?}"; exit $c' ERR

# Use sudo if not root
if [[ $EUID -ne 0 ]]; then SUDO="sudo"; else SUDO=""; fi
command -v sudo >/dev/null 2>&1 || { [[ $EUID -eq 0 ]] || { echo "Please run as root or install sudo."; exit 1; }; }

# Essentials
$SUDO apt-get update -y
$SUDO apt-get install -y git curl ca-certificates

# Clone repo under the current $HOME
BA_DIR="$HOME/blockassist"
say "$EMOJI_BOX" "Cloning blockassist into ${BA_DIR} …"
if [[ ! -d "$BA_DIR" ]]; then
  git clone https://github.com/gensyn-ai/blockassist.git "$BA_DIR"
fi

# cd to blockassist
cd "$BA_DIR"

# Run project Java installer if present (installs JDK under /opt)
if [[ -x ./setup.sh ]]; then
  say "$EMOJI_GEAR" "Running ./setup.sh (installs JDK under /opt) …"
  ./setup.sh
else
  say "$EMOJI_WARN" "No ./setup.sh found or not executable—skipping Java installer."
fi

# Locate JDK under /opt and set JAVA_HOME/PATH (works even if java not in PATH yet)
say "$EMOJI_GEAR" "Locating JDK under /opt and fixing JAVA_HOME …"
JDK_BIN="$(find /opt -maxdepth 4 -type f -name java -path '*/bin/java' -executable 2>/dev/null | head -n1 || true)"
if [[ -n "$JDK_BIN" ]]; then
  export JAVA_HOME="$(dirname "$(dirname "$JDK_BIN")")"
  export PATH="$JAVA_HOME/bin:$PATH"
  # Persist for future shells
  grep -q 'export JAVA_HOME=' ~/.bashrc 2>/dev/null || echo "export JAVA_HOME='$JAVA_HOME'" >> ~/.bashrc
  grep -q 'JAVA_HOME/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
  say "$EMOJI_OK" "JAVA_HOME=$JAVA_HOME"
  java -version || true
else
  say "$EMOJI_WARN" "Could not find /opt/**/bin/java. If java -version fails, check your JDK install."
fi

# Python build deps
say "$EMOJI_BOX" "Installing Python build dependencies …"
$SUDO apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv if missing
if [[ ! -d "${HOME}/.pyenv" ]]; then
  curl -fsSL https://pyenv.run | bash
fi

# Add clean pyenv init block
PYENV_BLOCK=$'# >>> pyenv >>>\nexport PYENV_ROOT=\"$HOME/.pyenv\"\nif [ -d \"$PYENV_ROOT/bin\" ]; then export PATH=\"$PYENV_ROOT/bin:$PATH\"; fi\nif command -v pyenv >/dev/null 2>&1; then eval \"$(pyenv init -)\"; fi\nif command -v pyenv-virtualenv-init >/dev/null 2>&1; then eval \"$(pyenv virtualenv-init -)\"; fi\n# <<< pyenv <<<'
touch "${HOME}/.bashrc" "${HOME}/.profile"
sed -i '/^# >>> pyenv >>>/,/^# <<< pyenv <<</d' "${HOME}/.bashrc"
printf '%s\n' "$PYENV_BLOCK" >> "${HOME}/.bashrc"
grep -q 'test -r ~/.bashrc && . ~/.bashrc' "${HOME}/.profile" || echo 'test -r ~/.bashrc && . ~/.bashrc' >> "${HOME}/.profile"

# Enable pyenv in this shell
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then export PATH="$PYENV_ROOT/bin:$PATH"; fi
eval "$(pyenv init -)" 2>/dev/null || true

# Install latest Python 3.10.x & venv
say "$EMOJI_GEAR" "Resolving latest Python 3.10.x in pyenv …"
PY310_LATEST="$(pyenv install -l | awk '{$1=$1};1' | grep -E '^3\.10\.[0-9]+$' | tail -1 || true)"
[[ -z "${PY310_LATEST:-}" ]] && PY310_LATEST="3.10.14"
say "$EMOJI_RUN" "Installing Python ${PY310_LATEST} via pyenv …"
pyenv install -s "$PY310_LATEST"

if command -v pyenv-virtualenv >/dev/null 2>&1; then
  pyenv virtualenv -f "$PY310_LATEST" blockassist-venv || true
  eval "$(pyenv init -)"; pyenv activate blockassist-venv
  PY_CMD="$HOME/.pyenv/versions/blockassist-venv/bin/python"
else
  pyenv local "$PY310_LATEST"
  python -m venv "${HOME}/.venvs/blockassist-venv"
  # shellcheck disable=SC1091
  source "${HOME}/.venvs/blockassist-venv/bin/activate"
  PY_CMD="$HOME/.venvs/blockassist-venv/bin/python"
fi

python -m pip install --upgrade pip
pip install psutil readchar

# Create a one-shot foreground launcher (no loop, no nohup)
say "$EMOJI_GEAR" "Creating launcher: ${BA_DIR}/run-blockassist.sh (foreground)"
cat > "${BA_DIR}/run-blockassist.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
BA_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BA_DIR"

# Ensure Java is available (detect /opt JDK if PATH lacks java)
if ! command -v java >/dev/null 2>&1; then
  JDK_BIN="$(find /opt -maxdepth 4 -type f -name java -path '*/bin/java' -executable 2>/dev/null | head -n1 || true)"
  if [[ -n "$JDK_BIN" ]]; then
    export JAVA_HOME="$(dirname "$(dirname "$JDK_BIN")")"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
fi

# Prefer the venv python we created
if [[ -x "$HOME/.pyenv/versions/blockassist-venv/bin/python" ]]; then
  PY_CMD="$HOME/.pyenv/versions/blockassist-venv/bin/python"
elif [[ -x "$HOME/.venvs/blockassist-venv/bin/python" ]]; then
  PY_CMD="$HOME/.venvs/blockassist-venv/bin/python"
else
  PY_CMD="python"
fi

# Display/X auth defaults (adjust if not using Kasm)
export DISPLAY=${DISPLAY:-:1}
export XAUTHORITY=${XAUTHORITY:-/home/kasm-user/.Xauthority}
export LIBGL_ALWAYS_SOFTWARE=1

exec "$PY_CMD" run.py
EOF
chmod +x "${BA_DIR}/run-blockassist.sh"

say "$EMOJI_OK" "Setup complete. 🎮"
echo
echo "Run (foreground):"
echo "  ${BA_DIR}/run-blockassist.sh"
echo
say "$EMOJI_INFO" "We cd into blockassist during setup and inside the launcher. JAVA_HOME is fixed via /opt JDK detection."
