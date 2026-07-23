# WORKLOG — PIE(중국) 작업분석 작업 일지

> 컨텍스트 요약(압축)으로 대화 내용이 유실되어도 작업 흐름을 잃지 않기 위한 진행 문서.
> **규칙: 의미 있는 작업이 끝날 때마다 이 문서를 업데이트하고 GitHub에 커밋+푸시한다. (사용자 허가 불필요, 자동 수행)**

---

## 표준 작업 방식 (사용자 지시, 2026-07-24 — 대시보드 프로젝트(2026-07-23 확립) 규칙을 동일 적용)

- 작업 단위가 끝날 때마다 이 문서 업데이트 → 커밋 → `origin/main` 푸시 (자동)
- 전문 에이전트 5명을 병렬로 운용한다. 역할:
  1. **작업분석 코어 전문가** — 구간(작업요소) 기록/편집, 자동 사이클 배정, 간트/차트, 통계, 레이팅·여유율→ST 계산, CSV, ECRS·서블릭 (PIE.html 분석 탭 계열)
  2. **AI·포즈 전문가** — MediaPipe Pose 연동(영상비교 오버레이), AI 동작분석, AI 비전 분석(YOLO `localhost:8000`), 비전 분석결과 패널, mediapipe/pose 로컬 자산
  3. **라인밸런싱·편성 전문가** — 야마즈미(작업배분), 작업자 시뮬, 작업편성, 재배분, ST분석, 라인예측, 병목 차트, 라인분석, 제약조건·대기시간
  4. **데이터 파이프라인·저장 전문가** — localStorage(wvas_*/pie_*) 스키마, .wvas 파일, E드라이브 저장(File System Access API), ST 누적 저장소(none/folder/server), PIE_ST_server.ps1 병합 로직
  5. **배포/QA·다국어 전문가** — 오프라인 무결성(외부 호출 0), bat/ps1/vbs 스크립트, 라이선스 게이트, i18n(ko/zh/vi), PDF, GitHub Pages 배포
- GitHub: `lovekhl83-stack/pie-work-analysis-cn` (**public** — Pages가 download.html·전체 zip을 서빙). `st_store.json`은 커밋 제외(.gitignore)
- ⚠ **공개 저장소 주의**: 이 문서와 PROJECT_OVERVIEW.md도 공개된다. 라이선스 키 알고리즘 상세·고객 정보는 문서에 기재 금지

## 프로젝트 현재 상태 스냅샷

- 전체 구조 문서: `PROJECT_OVERVIEW.md` (2026-07-24 정독 후 작성) — 구조 질문은 이 문서 먼저 볼 것
- 단일 파일 앱: `PIE.html` 12,386줄/1.86MB (React 18 min + jsPDF + html2canvas + MediaPipe Pose 내장)
- 실행: `PIE(중국).bat` → PIE_local_server.ps1(포트 8791 정적 서버) → 브라우저. file:// 직접 열면 Pose 기능 불가
- 부가 서버: `PIE_ST_server_시작.bat` → PIE_ST_server.ps1(포트 8792, LAN ST 누적 공유, st_store.json)
- 최대 리스크: ①설치 스크립트 4종이 PIE.html만 복사(설치본에서 Pose 불능) ②세션 30개 초과 시 고아 blob 누적→localStorage 고갈 ③zh 번역 누락(사전 1키+하드코딩 다수) ④folder 모드 ST 동기화 동시 쓰기 무잠금

---

## 진행 로그

### 2026-07-24

- **[완료] 대시보드 프로젝트의 표준 작업 방식 이관** — 사용자 지시로 대시보드(scan-dashboard)에서 확립한 규칙(작업 문서 자동 갱신+푸시, 5개 전문 에이전트 병렬 운용, 전체 정독 문서)을 이 프로젝트에 동일 적용
- **[완료] WORKLOG.md 신설 + 5개 전문 에이전트 체계 확립** (이 문서)
- **[중단] 첫 병렬 작업: 5개 분야 에이전트 정밀 감사** — 5개 에이전트 병렬 투입했으나 **세션 사용량 한도로 전원 중단**(결과 미회수). 재실행 대기(백로그 D)
- **[완료] 핵심부 직접 정독 + `PROJECT_OVERVIEW.md` 작성** — 스크립트/문서 전부 + PIE.html 핵심부(라이선스 시스템, i18n, 상수, 저장 계층 전체, ST 누적 저장소, App 골격, 세션/.wvas 저장, 시작·라이선스 화면, initPose, 설치기 동작) 선별 정독. 이 과정에서 아래 백로그 P0~P3 발견
- **[완료] 첫 커밋+푸시** — PROJECT_OVERVIEW.md, WORKLOG.md

## 백로그 (우선순위순)

표기: ✅=수정 착수(자동 진행 대상, 명백한 버그) / ❓=사용자 결정 대기 / ⏸=보류(후순위)

### P0 — 치명 (현장 배포 전 필수)
1. ❓ [배포] **설치 스크립트 4종(setup.bat, install.vbs, PIE_설치.ps1:186, PIE_setup.ps1:188) 전부 PIE.html 한 파일만 복사** — 설치본에 mediapipe/pose·PIE(중국).bat 부재 → Pose 영상비교 불능 + file:// 실행. 중국판 설치 표준을 "폴더 전체 복사형"으로 개편할지, 설치 스크립트를 제거하고 "폴더째 복사"를 공식화할지 결정 필요 (→결정 A)
2. ✅ [데이터] lsSave가 세션 목록을 30개로 자를 때 잘린 세션의 본문 blob(`wvas_sessions_<id>`)을 삭제하지 않음 — 고아 데이터 영구 누적 → localStorage(5MB) 고갈 → 이후 저장이 예외로 실패(lsSave에 try 없음, 사용자에게 무표시) (PIE.html:1243)

### P1 — 높음
3. ✅ [다국어] zh 사전에 `tab_lineanalysis` 키 누락 — 중국어 모드에서 라인분석 탭이 한국어 "라인분석"으로 표시 (PIE.html:1086~1118)
4. ✅ [다국어] StepGuide 초보자 4단계 안내가 한국어 하드코딩(+"눠러" 오타) — 초보자 모드가 기본값이라 중국 사용자 온보딩 안내가 전부 한국어 (PIE.html:2363~2374)
5. ❓ [다국어] alert/confirm/안내문 다수 한국어 하드코딩("불러오기 실패" 11043, "MediaPipe 아직 로딩 중" 8656, 간트 빈 화면 12255 등) — zh 전수 번역 범위 결정 필요 (→결정 C)
6. ❓ [보안] 라이선스 검증 로직·시크릿이 public 저장소의 PIE.html에 포함 — 코드를 읽으면 키 생성 가능. private 전환(Pages 배포 방식 변경 필요) vs 현행 수용 결정 (PIE.html:1015~1041) (→결정 B)
7. ⏸ [데이터] folder 모드 ST 동기화에 파일 잠금 없음 — 두 PC가 동시에 stBackendSync 하면 나중 쓰기가 먼저 쓰기의 병합분을 덮어씀(last-writer-wins). server 모드는 서버측 재병합으로 안전 (PIE.html:1468~1479)

### P2 — 중간
8. ✅ [서버] st_store.json 쓰기가 비원자적(Out-File 직접 덮어쓰기) — 쓰기 중 크래시 시 파손되고, 파손 파일은 ConvertFrom-Json 실패가 조용히 무시되어 다음 POST가 빈 기반 위에 저장(누적 데이터 증발) (PIE_ST_server.ps1:154~157)
9. ⏸ [호환] `AbortSignal.timeout` 사용 — 구형 Chromium(103 미만)이면 예외→ST 서버 동기화가 조용히 실패. 중국 현장의 구형 360/QQ 브라우저 확인 필요 (PIE.html:1461,1487)
10. ⏸ [입력] 중국어 IME 조합 중 단축키 I/O·Enter 동작 검증 필요 — 대시보드에서 동일 계열 버그(IME isComposing 미가드) 실증 전례 (PIE.html:10469~10480) *(추정, 실기 검증 필요)*
11. ✅ [브랜딩] StartupModal 부제 "Process Intelligence Engine" ↔ 정식 명칭 "Powernet Industrial Engineering" 불일치 (PIE.html:2353)
12. ⏸ [다국어] PIE_가이드.html의 ko/zh/vi 섹션 구성 일치 여부 미검증(zh에 "내보내기/제거" 섹션이 없어 보임 — 확인 필요)
13. ⏸ [정리] loadFromStorage/importFromFile/applyFileData 3중복 로드 로직 (PIE.html:11041~11116)

### P3 — 낮음/정책
14. ⏸ [정리] 원본 온라인판 잔재 — vi 사전(1119, UI 노출 없음), setup.bat/install.vbs, PDF 파일명 "WVAS-report"(11153), 가이드 "온라인/오프라인 기능" 섹션
15. ⏸ [견고성] uid()가 Math.random 7자리 — 충돌 확률 낮으나 세션·작업요소 id로 광범위 사용 (PIE.html:1214)
16. ⏸ [UX] file:// 직접 실행 감지·경고 없음 — Pose 실패 시점에야 문제 인지. 기동 시 location.protocol 체크로 안내 배너 가능

## 사용자 결정 대기 (질문 예정)

- A. **설치 방식 표준화**: 설치 스크립트 4종을 "폴더 전체 복사 + 시작 메뉴/바탕화면에 PIE(중국).bat 바로가기"형으로 개편? 아니면 스크립트 제거하고 "폴더째 복사"만 공식 절차로?
- B. **라이선스 노출**: public 저장소(전체 zip 공개 다운로드)에 검증 로직 포함 현행 유지? private 전환 시 download.html/Pages 배포 대안 필요
- C. **zh 번역 범위**: 알림·확인창·안내문까지 전수 번역? 핵심 화면만? (vi 잔재 제거 여부 포함)
- D. **5개 분야 정밀 감사 재실행**: 세션 한도로 중단된 병렬 감사를 언제 다시 돌릴지 (각 분야 에이전트가 담당 구간 전수 정독 → 백로그 보강)

## 결정 사항 기록

- 2026-07-24: 대시보드와 동일한 표준 작업 방식 적용 (WORKLOG 자동 업데이트+자동 푸시, 역질문 없이 진행, 5개 에이전트 병렬)
- 2026-07-24: 저장소가 public이므로 라이선스 알고리즘 상세는 문서화하지 않는다
