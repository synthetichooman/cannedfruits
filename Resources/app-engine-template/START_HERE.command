#!/bin/zsh

set -e

cd "$(dirname "$0")"

clear
echo "cannedfruits v0.1 설정을 시작합니다."
echo ""

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js가 설치되어 있지 않습니다."
  echo ""
  echo "아래 페이지가 열리면 Node.js LTS 버전을 설치한 뒤,"
  echo "이 START_HERE.command 파일을 다시 더블클릭하세요."
  echo ""
  open "https://nodejs.org/ko/download"
  echo "종료하려면 이 창을 닫아도 됩니다."
  read -r "?계속하려면 Enter를 누르세요."
  exit 1
fi

if ! node -e "const major = Number(process.versions.node.split('.')[0]); process.exit(major >= 18 ? 0 : 1)" >/dev/null 2>&1; then
  echo "현재 설치된 Node.js 버전이 너무 낮습니다."
  echo ""
  echo "cannedfruits는 Node.js 18 이상이 필요합니다."
  echo "아래 페이지가 열리면 Node.js LTS 버전을 설치한 뒤,"
  echo "이 START_HERE.command 파일을 다시 더블클릭하세요."
  echo ""
  open "https://nodejs.org/ko/download"
  echo "종료하려면 이 창을 닫아도 됩니다."
  read -r "?계속하려면 Enter를 누르세요."
  exit 1
fi

find_port() {
  for candidate in 8788 8789 8790 8791 8792 8793 8794 8795 8796 8797; do
    if ! lsof -ti tcp:$candidate >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done

  echo "8788"
}

export PORT="${PORT:-$(find_port)}"
PREVIEW_URL="http://localhost:${PORT}"

echo "웹 미리보기를 준비하고 있습니다."
echo ""
echo "미리보기: ${PREVIEW_URL}"
echo ""
echo "중요: 작업하는 동안 이 창을 닫지 마세요."
echo "종료하려면 이 창에서 Control + C를 누르면 됩니다."
echo ""

(sleep 1.4 && open "$PREVIEW_URL") &

node scripts/dev-server.mjs
