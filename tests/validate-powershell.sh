#!/bin/bash
# PowerShell 스크립트 배포 전 검증
# Windows 호환성 문제를 사전에 발견

set -e

echo "======================================================================"
echo "PowerShell 스크립트 검증"
echo "======================================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

FAILED=0
WARNINGS=0

# 1. BOM 검증
echo "1. UTF-8 BOM 검증..."
for file in *.ps1; do
    if [ ! -f "$file" ]; then continue; fi

    bom=$(head -c 3 "$file" | od -An -tx1 | tr -d ' ')

    if [ "$bom" = "efbbbf" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file - BOM 없음"
        FAILED=1
    fi
done
echo ""

# 2. 중복 BOM 검사
echo "2. BOM 중복 검사..."
for file in *.ps1; do
    if [ ! -f "$file" ]; then continue; fi

    first6=$(head -c 6 "$file" | od -An -tx1 | tr -d ' \n')

    if [ "$first6" = "efbbbfefbbbf" ]; then
        echo "   ✗ $file - BOM 중복 (PowerShell 파싱 오류 발생!)"
        FAILED=1
    else
        echo "   ✓ $file"
    fi
done
echo ""

# 3. 이모지 검사
echo "3. 이모지/특수문자 검사..."
if grep -P '[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]' *.ps1 2>/dev/null; then
    echo "   ✗ 이모지 발견 - Windows 인코딩 오류 발생!"
    FAILED=1
else
    echo "   ✓ 이모지 없음"
fi
echo ""

# 4. 잘못된 이미지 태그 검사
echo "4. Docker 이미지 태그 검사..."
if grep -n ':auto' *.ps1 2>/dev/null | grep -v '#'; then
    echo "   ✗ ':auto' 태그 발견 - 존재하지 않는 이미지!"
    FAILED=1
else
    echo "   ✓ 이미지 태그 정상"
fi
echo ""

# 5. UTF-8 인코딩 검사
echo "5. UTF-8 인코딩 검사..."
for file in *.ps1; do
    if [ ! -f "$file" ]; then continue; fi

    if file "$file" | grep -q "UTF-8"; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file - $(file -b "$file")"
        FAILED=1
    fi
done
echo ""

# 6. 한글 깨짐 테스트
echo "6. 한글 인코딩 테스트..."
for file in *.ps1; do
    if [ ! -f "$file" ]; then continue; fi

    if grep -q '[가-힣]' "$file"; then
        # 한글이 정상적으로 읽히는지 확인
        if iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1; then
            korean_lines=$(grep -c '[가-힣]' "$file" || true)
            echo "   ✓ $file - 한글 ${korean_lines}줄 정상"
        else
            echo "   ✗ $file - 한글 인코딩 손상"
            FAILED=1
        fi
    fi
done
echo ""

# 최종 결과
echo "======================================================================"
if [ $FAILED -eq 0 ]; then
    echo "✅ 모든 검증 통과! Windows 배포 가능합니다."
    echo "======================================================================"
    exit 0
else
    echo "❌ 검증 실패! 문제를 수정한 후 다시 실행하세요."
    echo "======================================================================"
    exit 1
fi
