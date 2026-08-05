# PIE(중국) — 프로그램 한눈에 보기

> **다른 대화창에서 이 프로그램을 파악할 때는 이 파일 하나만 먼저 읽으면 된다.**
> 더 깊게: 구조·내부 지도 → `PROJECT_OVERVIEW.md`, 진행 상황·버그 백로그 → `WORKLOG.md`, 작업 규칙 → `CLAUDE.md`
> 최종 갱신 2026-08-05

---

## 1. 30초 요약

**PIE (Powernet Industrial Engineering) — 중국(심양) 현장용 오프라인 IE 작업분석 프로그램.**

작업 영상을 보면서 작업요소(구간)를 마킹 → 시간연구(Time Study) → 레이팅·여유율로 **표준시간(ST)** 산출 → 야마즈미(작업배분)·라인 시뮬레이션·SOP/보고서 출력까지 이어지는 도구.

- 만든 사람/용도: 김형래(제조기술 파트), 아답터·SMPS 제조 현장(심양 법인) 작업분석용
- 형태: **단일 HTML 파일 앱** `PIE.html` (약 1.86MB, 12,000줄+). React 18·jsPDF·html2canvas·MediaPipe Pose가 파일 안에 전부 내장. **빌드 시스템 없음 — 파일을 직접 편집**
- 인터넷 **불필요**(런타임 외부 호출 0건 실측). 원본의 구글시트(GAS) 연동을 걷어내고 로컬/LAN 방식으로 대체한 빌드
- 첫 실행 시 라이선스 키 입력 (`PIE-XXXX-XXXX-XXXX`, 월 단위 만료). 문의 lovekhl83@gmail.com
- GitHub: `lovekhl83-stack/pie-work-analysis-cn` — ⚠ **public 저장소** (Pages가 다운로드 페이지 서빙). 라이선스 알고리즘·고객 정보는 문서·주석에 절대 기재 금지

## 2. 실행 방법

```
PIE(중국).bat 더블클릭
  → PIE_local_server.ps1 (PowerShell 정적 서버, 127.0.0.1:8791)
  → 기본 브라우저 자동 오픈
```

- 검은 명령창을 닫으면 종료. 브라우저가 안 뜨면 주소창에 `http://127.0.0.1:8791/PIE.html` 직접 입력
- ⚠ `PIE.html`을 더블클릭(file://)해도 열리지만 **MediaPipe Pose 기능이 동작하지 않는다** — 반드시 bat으로 실행
- 브라우저는 **Chrome / Edge 최신판 필수** (File System Access API, AbortSignal.timeout 사용)
- 부가 서버(선택): `PIE_ST_server_시작.bat` → 포트 8792, LAN으로 부품 ST 누적을 여러 PC가 공유

## 3. 파일 지도

| 파일 | 역할 |
|---|---|
| `PIE.html` | **앱 전체** (단일 파일) |
| `PIE(중국).bat` → `PIE_local_server.ps1` | 표준 실행 / 정적 서버 8791 |
| `PIE_ST_server_시작.bat` → `PIE_ST_server.ps1` | ST 누적 공유 서버 8792 (`st_store.json`, 커밋 제외) |
| `mediapipe/pose/` | Pose 모델 자산 8파일 (오프라인 동봉) |
| `PIE_설치.bat` → `PIE_setup.ps1` / `PIE_제거.bat` → `PIE_uninstall.ps1` | 설치기·제거기 (2026-07-26부터 **폴더 전체** 설치형) |
| `PIE_가이드.html` | 사용 가이드 (ko/zh/vi 3언어, 8섹션) |
| `download.html` + `.github/workflows/pages.yml` | GitHub Pages 배포용 다운로드 랜딩 |
| `PROJECT_OVERVIEW.md` / `WORKLOG.md` / `CLAUDE.md` | 구조 문서 / 작업 일지·백로그 / 작업 규칙 |

## 4. 기능 요약

- **작업**: 작업분석(구간 마킹·서블릭·ECRS) / 차트(간트 3뷰) / 통계(사이클별 CV·이상치·필요관측수) / 영상비교
- **라인**: 라인분석 / 야마즈미=작업배분(제약·대기시간 반영, FFD 재배치) / 시뮬(배치실험)
- **도구**: 부품관리(부품 ST DB·영상분석이력) / 라인예측 / AI 비전 분석(Pose)
- **메뉴**: 세션, CSV·PDF 내보내기, 모델관리, 낭비구간 비교, 사이클 속도 비교, SOP, 산출보고서, 용어집, 설정
- **단축키**: Space 재생/정지, ←→ 1프레임(Shift=5초), **I**=시작 마킹 / **O**=끝 마킹, Esc 루프 해제
- **초보자 모드 기본 ON** — 탭 이름이 쉬운 말(야마즈미→작업배분) + StepGuide 4단계 안내
- **핵심 수식**: `ST = 관측시간 × (레이팅/100) × (1 + 여유율/100)` — 기본 레이팅 100, 여유율 15%
- **AI(전부 로컬)**: AI 비전 분석 = MediaPipe Pose + DTW로 정미/대기·낭비/이동 자동 판정. AI 동작분석(YOLO, `localhost:8000`)은 백엔드 미동봉이라 **메뉴 숨김 상태**(코드는 보존)

## 5. 데이터가 저장되는 곳

- **localStorage**: 세션(최대 30개) `wvas_sessions*`, 모델·부품 마스터, **부품 ST DB** `wvas_part_st`, 레이팅, 라인분석 `pie_line_*`, 언어·라이선스 키
- **파일**: `.wvas` 내보내기(작업분석 구간만) / 메뉴 > 분석 저장(폴더에 `project.json` v4 — 라인분석·작업배분·**영상까지** 복원)
- **ST 누적 공유**: none / folder(공유폴더 `PIE_ST_누적.json`) / server(LAN 8792) 3모드. 병합은 **표본수 n 큰 쪽 우선 → 최신 우선**(합산 아님)이라 반복 동기화해도 값이 부풀지 않음. 삭제·리셋은 tombstone으로 전 PC 전파
- ⚠ **영상 원본은 세션/.wvas에 저장되지 않는다** — 불러온 뒤 영상 재선택 필요 (통합 프로젝트 저장만 예외)

## 6. 현재 상태 (2026-07-28)

- P0 3건·P1 11건·P2 18건 수정 완료, 매번 브라우저 실행 검증 완료. 사용자 결정 A~F 전부 확정·반영됨
- 남은 진행형: **zh 번역 잔여**(알림창은 완료, 본문 화면은 여전히 상당수 한국어) / SOP PDF의 CJK 깨짐 / P3 정리 묶음
- 알아둘 구조적 특성: ST 수식이 16곳에 산재(공용 함수 없음) · 택트 값이 3곳으로 갈림 · 죽은 코드 군 존재 · 비전 분석 결과는 새로고침 시 소실
