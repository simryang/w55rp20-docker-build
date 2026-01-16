# 변수 레퍼런스

## 사용자 변경 가능

| 변수 | 기본값 | 용도 | 설정 위치 |
|------|--------|------|-----------|
| JOBS | 16 | 빌드 병렬도 | build.config / 환경변수 |
| TMPFS_SIZE | 24g | RAM 디스크 크기 | build.config / 환경변수 |
| IMAGE | w55rp20:auto | 이미지 이름 | build.config / 환경변수 |
| AUTO_BUILD_IMAGE | 1 | 자동 빌드 | build.config / 환경변수 |
| UPDATE_REPO | 0 | 소스 갱신 | 환경변수 |
| CLEAN | 0 | 산출물 정리 | 환경변수 |
| BUILD_TYPE | Release | 빌드 타입 | build.config / 환경변수 |
| VERBOSE | 0 | 상세 출력 | 환경변수 |
| REFRESH | "" | 캐시 무효화 | 환경변수 |

## 내부 변수 (자동 생성)

| 변수 | 생성 위치 | 용도 |
|------|-----------|------|
| REFRESH_APT_BUST | build.sh | apt 캐시 버스트 |
| REFRESH_SDK_BUST | build.sh | sdk 캐시 버스트 |
| REFRESH_CMAKE_BUST | build.sh | cmake 캐시 버스트 |
| REFRESH_GCC_BUST | build.sh | gcc 캐시 버스트 |
| _BUST | build.sh | timestamp |

## 전달 체인

```
사용자 환경변수
  ↓
build.sh (파싱/생성)
  ↓ export + env
w55build.sh (Docker 빌드/실행)
  ↓ -e 옵션
docker-build.sh (실제 빌드)
```
