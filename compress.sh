#!/bin/bash
# create-safe-archive.sh

set -e

SOURCE_DIR="/Users/wonseok/project-iamwonseok/agent-context"
OUTPUT_FILE="$HOME/Desktop/agent-context-$(date +%Y%m%d-%H%M%S).zip"

cd "$SOURCE_DIR"

# Git 추적 파일만 압축 (.secrets 등 자동 제외)
git archive --format=zip --output="$OUTPUT_FILE" HEAD

echo "========================================="
echo "파일 생성 완료: $OUTPUT_FILE"
echo "========================================="
echo ""
echo "다음 단계:"
echo "1. 브라우저에서 drive.google.com 접속 (Okta 지문인증)"
echo "2. 원하는 폴더로 이동"
echo "3. 드래그 앤 드롭으로 업로드"
echo ""
open "$HOME/Desktop"  # Finder에서 Desktop 열기
