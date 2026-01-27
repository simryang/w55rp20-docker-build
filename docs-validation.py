#!/usr/bin/env python3
# docs-validation.py - 문서 검증 스크립트
# 작성일: 2026-01-21

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple

# 색상 정의
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color

# 카운터
class Stats:
    def __init__(self):
        self.total_checks = 0
        self.passed_checks = 0
        self.failed_checks = 0
        self.warnings = 0

stats = Stats()

def print_header(text: str):
    """섹션 헤더 출력"""
    print(f"\n{Colors.BOLD}━━━ {text} ━━━{Colors.NC}\n")

def check_pass(message: str):
    """통과 체크"""
    print(f"{Colors.GREEN}[PASS]{Colors.NC} {message}")
    stats.passed_checks += 1
    stats.total_checks += 1

def check_fail(message: str):
    """실패 체크"""
    print(f"{Colors.RED}[FAIL]{Colors.NC} {message}")
    stats.failed_checks += 1
    stats.total_checks += 1

def check_warn(message: str):
    """경고 체크"""
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {message}")
    stats.warnings += 1
    stats.total_checks += 1

def check_file_exists(files: List[str], description: str):
    """파일 존재 확인"""
    print_header(f"1. {description}")

    for file_path in files:
        if Path(file_path).is_file():
            check_pass(f"{file_path} 존재")
        else:
            check_fail(f"{file_path} 없음")

def validate_markdown_links(file_path: str) -> List[str]:
    """마크다운 링크 검증"""
    broken_links = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # .md 링크 추출: [text](link.md) 또는 [text](link.md#anchor)
        pattern = r'\[([^\]]+)\]\(([^)]+\.md[^)]*)\)'
        matches = re.findall(pattern, content)

        # 파일이 있는 디렉토리 가져오기
        file_dir = Path(file_path).parent

        for text, link in matches:
            # 앵커 제거
            file_only = link.split('#')[0]

            if file_only:
                # 상대 경로를 파일 디렉토리 기준으로 해석
                target_path = file_dir / file_only
                if not target_path.is_file():
                    broken_links.append(f"{file_path}: 깨진 링크 → {link}")

    except Exception as e:
        broken_links.append(f"{file_path}: 읽기 오류 - {e}")

    return broken_links

def check_markdown_links(files: List[str]):
    """마크다운 링크 검증"""
    print_header("2. 마크다운 링크 검증")

    for file_path in files:
        if not Path(file_path).is_file():
            continue

        broken_links = validate_markdown_links(file_path)

        if broken_links:
            check_warn(f"{file_path}: 깨진 링크 발견")
            for link in broken_links:
                print(f"     → {link}")
        else:
            check_pass(f"{file_path}: 링크 정상")

def check_file_sizes(files: List[str]):
    """문서 크기 확인"""
    print_header("3. 문서 크기 확인")

    for file_path in files:
        if not Path(file_path).is_file():
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = len(f.readlines())

            size_bytes = Path(file_path).stat().st_size
            size_kb = size_bytes / 1024

            if lines > 0:
                check_pass(f"{file_path}: {lines:,}줄, {size_kb:.1f}KB")
            else:
                check_fail(f"{file_path}: 빈 파일")

        except Exception as e:
            check_fail(f"{file_path}: 읽기 오류 - {e}")

def check_code_blocks(files: List[str]):
    """코드 블록 검증 (``` 짝 맞는지)"""
    print_header("4. 코드 블록 검증")

    for file_path in files:
        if not Path(file_path).is_file():
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # ``` 개수 세기
            count = content.count('```')

            if count % 2 == 0:
                check_pass(f"{file_path}: 코드 블록 정상 ({count//2}개)")
            else:
                check_fail(f"{file_path}: 코드 블록 불균형 (홀수 개: {count})")

        except Exception as e:
            check_fail(f"{file_path}: 읽기 오류 - {e}")

def check_encoding(files: List[str]):
    """UTF-8 인코딩 확인"""
    print_header("5. 인코딩 확인")

    for file_path in files:
        if not Path(file_path).is_file():
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                f.read()
            check_pass(f"{file_path}: UTF-8 인코딩")
        except UnicodeDecodeError:
            check_warn(f"{file_path}: UTF-8이 아님")
        except Exception as e:
            check_fail(f"{file_path}: 읽기 오류 - {e}")

def check_required_sections(file_sections: dict):
    """필수 섹션 확인"""
    print_header("6. 필수 섹션 확인")

    for file_path, sections in file_sections.items():
        if not Path(file_path).is_file():
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            for section in sections:
                # 헤딩에서 섹션 찾기 (# 으로 시작하는 라인)
                pattern = rf'^#+.*{re.escape(section)}'
                if re.search(pattern, content, re.MULTILINE):
                    check_pass(f"{file_path}: '{section}' 섹션 있음")
                else:
                    check_warn(f"{file_path}: '{section}' 섹션 없음")

        except Exception as e:
            check_fail(f"{file_path}: 읽기 오류 - {e}")

def check_scripts(scripts: List[str]):
    """스크립트 파일 확인"""
    print_header("7. 빌드 스크립트 확인")

    for script in scripts:
        if Path(script).is_file():
            check_pass(f"{script} 존재")

            # .sh 파일은 실행 권한 확인
            if script.endswith('.sh'):
                if os.access(script, os.X_OK):
                    check_pass(f"{script}: 실행 권한 있음")
                else:
                    check_warn(f"{script}: 실행 권한 없음")
        else:
            check_fail(f"{script} 없음")

def calculate_statistics(all_files: List[str]):
    """문서 통계"""
    print_header("8. 문서 통계")

    total_lines = 0
    total_size = 0
    total_docs = 0

    for file_path in all_files:
        if not Path(file_path).is_file():
            continue

        total_docs += 1

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = len(f.readlines())
            total_lines += lines

            size_bytes = Path(file_path).stat().st_size
            total_size += size_bytes
        except:
            pass

    print(f"총 문서 수: {total_docs}개")
    print(f"총 줄 수: {total_lines:,}줄")
    print(f"총 크기: {total_size / 1024:.1f}KB")

def print_summary():
    """결과 요약"""
    print(f"\n{Colors.BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.BOLD}  검증 결과{Colors.NC}")
    print(f"{Colors.BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")

    print(f"총 검사 항목: {stats.total_checks}")
    print(f"{Colors.GREEN}통과: {stats.passed_checks}{Colors.NC}")
    print(f"{Colors.RED}실패: {stats.failed_checks}{Colors.NC}")
    print(f"{Colors.YELLOW}경고: {stats.warnings}{Colors.NC}")

    if stats.failed_checks == 0:
        print(f"\n{Colors.GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
        print(f"{Colors.GREEN}  모든 검증 통과{Colors.NC}")
        print(f"{Colors.GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
        return 0
    else:
        print(f"\n{Colors.RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
        print(f"{Colors.RED}  검증 실패 항목이 있습니다{Colors.NC}")
        print(f"{Colors.RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
        return 1

def main():
    """메인 함수"""
    print(f"{Colors.BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.BOLD}  문서 검증 시작{Colors.NC}")
    print(f"{Colors.BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")

    # 필수 문서 목록
    required_docs = [
        "README.md",
        "docs/BEGINNER_GUIDE.md",
        "docs/USER_GUIDE.md",
        "docs/ARCHITECTURE.md",
        "docs/BUILD_LOGS.md",
        "docs/TROUBLESHOOTING.md",
        "docs/EXAMPLES.md",
        "docs/QUICKREF.md",
        "docs/GLOSSARY.md",
        "docs/CHANGELOG.md",
        "docs/INSTALL_LINUX.md",
        "docs/INSTALL_MAC.md",
        "docs/INSTALL_WINDOWS.md",
        "docs/INSTALL_RASPBERRY_PI.md",
    ]

    # claude 폴더 문서
    claude_docs = [
        "claude/README.md",
        "claude/SESSION_SUMMARY.md",
        "claude/IMPLEMENTATION_LOG.md",
        "claude/DOCUMENTATION_MASTER_PLAN.md",
        "claude/DESIGN.md",
        "claude/DESIGN_DISCUSSIONS.md",
        "claude/UX_DESIGN.md",
        "claude/ADVANCED_OPTIONS.md",
        "claude/VARIABLES.md",
        "claude/ISSUES.md",
        "claude/GPT_INSTRUCTIONS.md",
    ]

    # 빌드 스크립트
    scripts = [
        "build.sh",
        "w55build.sh",
        "docker-build.sh",
        "entrypoint.sh",
        "Dockerfile",
    ]

    # 필수 섹션 (파일별)
    required_sections = {
        "README.md": ["빠른 시작", "문서 가이드", "FAQ"],
        "docs/BEGINNER_GUIDE.md": ["Docker", "첫 빌드"],
        "docs/TROUBLESHOOTING.md": ["빠른 진단", "Docker 관련"],
    }

    # 검증 실행
    check_file_exists(required_docs, "필수 문서 존재 확인")
    check_file_exists(claude_docs, "claude 폴더 문서 확인")
    check_markdown_links(required_docs + claude_docs)
    check_file_sizes(required_docs)
    check_code_blocks(required_docs)
    check_encoding(required_docs)
    check_required_sections(required_sections)
    check_scripts(scripts)
    calculate_statistics(required_docs + claude_docs)

    # 결과 요약
    return print_summary()

if __name__ == "__main__":
    sys.exit(main())
