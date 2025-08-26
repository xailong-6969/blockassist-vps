#!/usr/bin/env bash
set -e

if [ ! -d "$HOME/blockassist" ]; then
  git clone https://github.com/gensyn-ai/blockassist.git "$HOME/blockassist"
fi
cd "$HOME/blockassist"

./setup.sh

if [ ! -d "$HOME/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then export PATH="$PYENV_ROOT/bin:$PATH"; fi
eval "$(pyenv init - 2>/dev/null || true)"

if ! grep -q 'PYENV_ROOT="$HOME/.pyenv"' ~/.bashrc 2>/dev/null; then
  cat >>~/.bashrc <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then export PATH="$PYENV_ROOT/bin:$PATH"; fi
eval "$(pyenv init -)"
EOF
fi

if command -v sudo >/dev/null 2>&1; then SUDO=sudo; else SUDO=""; fi
$SUDO apt update -y
$SUDO apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

PY310="$(pyenv install -l | awk '{$1=$1};1' | grep -E '^3\.10\.[0-9]+$' | tail -1 || echo 3.10.14)"
pyenv install -s "$PY310"
pyenv local "$PY310"

python -m pip install --upgrade pip
pip install psutil readchar

if [ -f /home/kasm-user/.Xauthority ]; then
  DISPLAY=${DISPLAY:-:1} XAUTHORITY=/home/kasm-user/.Xauthority LIBGL_ALWAYS_SOFTWARE=1 python run.py
else
  python run.py
fi
