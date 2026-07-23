# PIE(중국) — Powernet Industrial Engineering 오프라인/중국 빌드 — 프로젝트 전체 문서

> 2026-07-24 기준, `D:\김형래\프로그램\작업분석 중국` 폴더의 파일을 정독하고 작성한 종합 문서.
> 공정관리·대시보드 프로젝트의 자매 프로젝트이며, 동일하게 **중국 현지 오프라인 전용 배포**를 전제로 한다.
> PIE.html(12,386줄)은 저장 계층·라이선스·App 골격·시작 화면·핵심 워크플로를 직접 정독했고, 세부 컴포넌트 전수 정독은 5개 분야 에이전트 감사(WORKLOG 백로그 참조)에서 보강한다.

---

## 1. 프로젝트 개요

- **이름**: PIE — Powernet Industrial Engineering (화면 부제: "작업 분석 시스템" / 시작화면 부제 "Process Intelligence Engine" ← 불일치, 백로그)
- **목적**: 작업 영상을 보면서 작업요소(구간)를 마킹해 시간연구(Time Study)를 수행하고, 레이팅·여유율로 표준시간(ST)을 산출, 야마즈미·작업편성·라인 시뮬레이션까지 이어지는 **IE 작업분석 도구**
- **이 빌드의 특징**: 인터넷 없는 중국 현장용. 원본의 구글 시트(GAS) 연동을 제거하고 ①부품 ST 누적을 로컬 파일/폴더/LAN 서버로 대체 ②MediaPipe Pose 모델을 `mediapipe/pose/`에 동봉 ③라이선스·시작 화면에 한국어/중국어 토글 추가
- **형태**: **단일 HTML 파일 앱** — `PIE.html` 하나(1.86MB, 12,386줄)에 React 18(min)+jsPDF+html2canvas+MediaPipe Pose JS+앱 코드 전부 내장. 빌드 시스템 없음(파일 직접 편집)
- **실행**: `PIE(중국).bat` → PowerShell 정적 서버(포트 8791) → 기본 브라우저 오픈. file:// 직접 열면 MediaPipe fetch가 막혀 Pose 기능 불가
- **라이선스**: 첫 실행 시 `PIE-XXXX-XXXX-XXXX`(12자리 hex) 키 입력, 연·월 단위 만료. 문의 lovekhl83@gmail.com
- **GitHub**: `lovekhl83-stack/pie-work-analysis-cn` (**public**) — GitHub Pages가 download.html(전체 zip 다운로드 페이지)을 서빙. `st_store.json`만 .gitignore

### 기술 스택
| 구분 | 내용 |
|---|---|
| UI | React 18 (min, CDN판 내장) — JSX 없이 `React.createElement` 직접 호출 |
| PDF | jsPDF + html2canvas (화면 스크린샷→JPEG→PDF, 래스터 방식이라 CJK 폰트 문제 없음) |
| AI | MediaPipe Pose (JS+wasm+tflite 로컬 동봉, modelComplexity 0=lite) / YOLO는 `localhost:8000` 별도 서버 |
| 서버 | 순수 PowerShell `System.Net.HttpListener` 2종 (정적 8791 / ST 공유 8792) — Node·Python 설치 불필요 |
| 저장 | localStorage + File System Access API(Chrome/Edge 전용) + `.wvas`/`.pie` JSON 파일 |

---

## 2. 폴더 구조

```
작업분석 중국\
├─ PIE.html                 # 앱 전체 (단일 파일, 1.86MB)
├─ PIE(중국).bat             # 표준 실행: PIE_local_server.ps1 구동
├─ PIE_local_server.ps1     # 정적 서버 (127.0.0.1:8791, 포트 사용 중이면 +20까지 탐색)
├─ PIE_ST_server_시작.bat    # LAN ST 누적 서버 실행
├─ PIE_ST_server.ps1        # ST 공유 서버 (+:8792, GET/POST /api/st, st_store.json 병합 저장)
├─ mediapipe\pose\           # Pose 모델 자산 8파일 (tflite/wasm/binarypb/data/loader js)
├─ setup.bat / install.vbs  # 구형 간이 설치: PIE.html만 바탕화면 복사 (⚠ mediapipe 미복사)
├─ PIE_설치.bat → PIE_설치.ps1   # GUI 설치기(한국어): %LOCALAPPDATA%\PIE_WorkAnalysis에 PIE.html만 복사 + 제거 레지스트리(HKCU) 등록
├─ PIE_setup.ps1            # GUI 설치기(한/영/베 3언어, 중국·베트남 Windows 폰트 폴백) — 역시 PIE.html만 복사
├─ PIE_제거.bat → PIE_제거.ps1   # 설치 폴더+레지스트리 제거
├─ PIE_가이드.html           # 설치·사용 가이드 (ko/zh/vi 3언어 섹션)
├─ download.html            # GitHub Pages 랜딩: main.zip 다운로드 버튼 + 최근 커밋일 표시
├─ README.md                # 실행/설치/주의사항
├─ .github\workflows\pages.yml  # push→Pages 배포 (전체 폴더를 artifact로 업로드)
└─ .nojekyll / .gitignore(st_store.json)
```

⚠ **설치 스크립트 4종(setup.bat, install.vbs, PIE_설치, PIE_setup) 전부 PIE.html "한 파일만" 복사한다** — 설치본에는 mediapipe 자산·실행 bat이 없어 Pose 비교가 동작하지 않는다. 중국판 공식 절차는 "폴더째 복사 + PIE(중국).bat"이다 (README 명시, 백로그 A 참조).

---

## 3. PIE.html 내부 지도 (줄 번호)

| 구간 | 내용 |
|---|---|
| 1~1014 | 내장 라이브러리: React/ReactDOM(min), MediaPipe Pose glue, jsPDF+플러그인, html2canvas |
| 1015~1041 | **PIE 라이선스 시스템** — `window._pieLicCheck(key)` 해시 기반 오프라인 검증. 12자리 hex, {year, month} 반환 (상세 알고리즘은 public 저장소이므로 문서화하지 않음) |
| 1042~1154 | **i18n STRINGS** — ko(53키)/zh(52키)/vi(53키). UI 토글은 ko/zh만, vi는 원본 잔재. **zh에 `tab_lineanalysis` 누락** |
| 1155~1201 | 상수: TT(정미/부수/낭비 3분류), TASK_COLORS 20색, CYCLE_COLORS 10색, THERBLIGS 18종, ECRS_LIST, SPEEDS(0.1~4x), WHEEL_PRESETS(30~100ms) |
| 1202~1231 | 유틸(fmt/fmtS/uid) + `autoAssignCycles` — 최다 빈도 작업명을 앵커로 사이클 경계 추정, 최대 10사이클 |
| 1237~1296 | localStorage 헬퍼: 세션(최대 30개)/모델-공정/부품 마스터(기본 11종: DIODE·TRANS 등 PCB 삽입부품)/부품 ST DB/레이팅(기본 r100·a15)/작업자 |
| 1299~1378 | E드라이브 저장: IndexedDB에 디렉터리 핸들 보관 → `.wvas` 파일 저장/목록/읽기/삭제 (File System Access API) |
| 1381~1506 | **ST 누적 저장소** — none/folder/server 3모드, `PIE_ST_누적.json`, `_stPickBetter`(표본수 n 우선→최신 updatedAt) + `mergePartStPayload`(부품명 소문자 기준 통합) + `stBackendSync`(읽기→병합→로컬 반영→쓰기) |
| 1514~2388 | 공용 컴포넌트: DualTimeDisplay, WheelStepControl, VideoWithOverlay, VideoCtrlMenu, HomeDashboard(1672), GanttTimeline(1734)/GanttByName(1802), SettingsModal(1889), LoadProjectModal(2021), ProjectMenuDropdown(2105), LeftSidebar(2161), WelcomeModal(2266), StartupModal(2320, ko/zh 토글), StepGuide(2363, ⚠한국어 하드코딩) |
| 2389~3341 | CycleComparison(2389), CycleStats(2967) — 사이클 반복 분석 |
| 3342~5134 | 라인 계열: Yamazumi(3342, `wvas_constraints`·`wvas_waittimes`), WorkerSim(4237), WorkAssignmentTab(4382), RebalanceWorkspace(4688), STAnalysis(4849), LinePredict(4941), BottleneckChart(5076) |
| 5135~5952 | FileManager(5135), PartsManager(5213), ModelBrowserModal(5664) |
| 5953~6204 | AiAnalysisModal — YOLO `localhost:8000` 연동 (AI 동작분석) |
| 6205~6582 | TaskDictBtn, GlossaryModal, IETip, TherbligPicker, ECRSCell, EcrsPanel |
| 6583~7214 | SegmentCompareModal(6583), VideoCompareModal(6907) |
| 7215~7679 | SopExportModal(7215), ReportModal(7304) — SOP/산출보고서 |
| 7680~9829 | VisionResultPanel + Pose 비교 엔진: initPose(8643, `locateFile→'mediapipe/pose/'+f`), VidPanel(8963), DTW 기반 구간 비교 |
| 9830~10387 | LineAnalysisPanel — 부품별 평균시간→작업배분 연동 (`pie_line_workers/tasks/model` 키) |
| 10388~12274 | **App()** — 전체 상태·탭 라우팅·키보드 단축키(Space/←→/I/O/Esc)·세션 저장/불러오기·.wvas 내보내기/가져오기·exportPDF(html2canvas) |
| 12276~12360 | LicenseScreen (ko/zh 토글, `pie_license_key` 저장) |
| 12361~12383 | ErrorBoundary + LicensedApp(키 검증→만료 확인→App) + `ReactDOM.createRoot` 부트스트랩 |

---

## 4. 데이터 모델·저장

### localStorage 키 전체
| 키 | 내용 |
|---|---|
| `wvas_sessions` | 세션 메타 목록 (최신순, **30개 캡** — 초과분은 목록에서 잘림) |
| `wvas_sessions_<id>` | 세션 데이터 본문 (작업요소 배열 등. ⚠ 30개 캡에서 잘린 세션의 본문은 미삭제 → 고아 누적, 백로그) |
| `wvas_models` | 모델-공정 트리 (공정에 tasks/fps/rating/takt 스냅숏 저장, `loadFromProcess`로 복원) |
| `wvas_parts` | 부품 마스터 (기본 11종 PCB 부품: id/name/insertType(Radial·Axial)/leadCount) |
| `wvas_part_st` | **부품 표준시간 DB** (모델 무관): `{partId: {taskName: {st, n(표본수), updatedAt, ...}}}` |
| `wvas_part_taskdb_reset` | 부품 ST 초기화 이력 |
| `wvas_rating` | 레이팅·여유율 (기본 `{r:100, a:15}`) |
| `wvas_workers` | 작업자 마스터 (기본 작업자1~3) |
| `wvas_constraints` / `wvas_waittimes` | 야마즈미 배분 제약 / 대기시간 |
| `wvas_lang` | 언어 'ko'/'zh' | 
| `wvas_expert` / `wvas_welcomed` / `wvas_adv_cols` | 초보자 모드 해제 / 웰컴 표시 여부 / 고급 컬럼 표시 |
| `pie_line_workers` / `pie_line_tasks` / `pie_line_model` | 라인분석 탭 전용 (작업자/작업/모델명) |
| `pie_st_backend_mode` / `_url` / `_folder_name` | ST 누적 저장소 모드('none'\|'folder'\|'server')/서버 주소/폴더 표시명 |
| `pie_license_key` | 활성화된 라이선스 키 |
| IndexedDB `wvas_fs` | 디렉터리 핸들 2개: `dirHandle`(E드라이브 저장), `stDirHandle`(ST 공유 폴더) |

### .wvas 프로젝트 파일 (내보내기/E드라이브 저장 공통, version 2)
```jsonc
{ "version":2, "savedAt":"ISO", "analysisName":"", "videoName":"", "fps":30,
  "tasks":[...],                      // 단일 영상 모드 하위호환
  "videos":[{id,name,tasks,fps,completed}], // 다중 영상. src는 저장 안 함(null)
  "activeVideoId":"", "partId":"" }
```
- **영상 원본은 어디에도 저장하지 않는다** — 불러오면 `src:null`로 복원되어 영상 파일을 다시 끌어와야 함 (의도된 설계: 용량)
- 같은 로드 로직이 loadFromStorage/importFromFile/applyFileData 3곳에 중복 (11041~11116, 리팩터 후보)

### ST 누적 저장소 (이 빌드의 핵심 대체 기능 — 구글시트 GAS 대신)
| 모드 | 동작 |
|---|---|
| none | 로컬 localStorage만 사용 |
| folder | 공유 폴더의 `PIE_ST_누적.json`을 읽고→로컬과 병합→다시 씀 (File System Access API, 핸들은 IndexedDB에 보관) |
| server | `<url>/api/st` GET→병합→POST. 서버(PIE_ST_server.ps1)는 POST 수신 시 **서버측에서 한 번 더 병합** 후 st_store.json에 저장 |

병합 규칙(클라이언트 JS와 서버 PS1이 동일 로직으로 구현됨):
1. 부품은 **이름 소문자 기준** 통합(id가 달라도 같은 이름이면 같은 부품으로 매핑)
2. 같은 부품·같은 작업명의 ST 항목은 `_stPickBetter`: **표본수 n 큰 쪽 우선, 같으면 updatedAt 최신 쪽** — 합산이 아닌 "선택"이라 반복 동기화해도 값이 부풀지 않음
- folder 모드는 파일 잠금이 없어 두 PC 동시 동기화 시 last-writer-wins (server 모드는 서버가 순차 병합하므로 안전)

---

## 5. 화면 구성과 워크플로

### 내비게이션 (LeftSidebar 2161, 상단 ProjectMenuDropdown 2105)
- **작업**: 작업분석(analysis) / 차트(gantt: timeline·byname·cycle 3뷰) / 통계(stats) / 영상비교(모달)
- **라인**: 라인분석(lineanalysis) / 야마즈미=작업배분(yamazumi) / 시뮬=배치실험(sim)
- **도구**: 부품관리(parts) / ST분석(st) / 작업편성(assign) / 라인예측(line) / AI 비전 분석·AI 분석결과(vision)
- **메뉴**: 세션, CSV·PDF 내보내기, 모델, AI 동작분석, 낭비 구간 비교, 사이클 속도 비교, SOP, 산출보고서, 도움말, 용어집, 설정
- 초보자 모드(기본): 탭 이름이 쉬운 말로 바뀌고(야마즈미→작업배분) StepGuide 4단계 안내 표시. `wvas_expert` 설정 시 해제

### 기본 워크플로
1. 영상 드래그&드롭(다중 가능) → analysis 탭
2. 재생하며 **I**(시작)/**O**(끝) 또는 클릭으로 작업요소 마킹 → 이름/유형(정미·부수·낭비)/서블릭/ECRS 부여
3. `autoAssignCycles`가 반복 사이클 자동 배정(최대 10) → 차트·사이클비교·통계
4. 레이팅(기본 100)·여유율(기본 15%)로 ST 산출 → 부품 ST DB에 누적(`wvas_part_st`) → ST 누적 저장소로 PC 간 공유
5. 라인분석에서 작업자별 영상 분석 → 야마즈미 배분(제약·대기시간 반영) → 시뮬 → SOP/보고서/PDF/CSV 출력
- 키보드: Space 재생/정지, ←→ 1프레임(Shift=5초), I/O 마킹, Esc 루프 해제. 마우스 휠 스텝 30/50/67/100ms

### AI 기능 (모두 로컬)
- **Pose 영상비교**: MediaPipe Pose(경량 모델 complexity 0) 2영상 병렬 추론→손목 속도·DTW로 구간 비교. 자산은 `mediapipe/pose/` 로컬 서빙 — **8791 서버 실행이 전제**
- **AI 동작분석/비전 분석(YOLO)**: `localhost:8000`에 별도 설치된 로컬 서버 필요. 미설치 시 안내만

---

## 6. 부가 서버 2종 (순수 PowerShell, 설치 불필요)

| | PIE_local_server.ps1 | PIE_ST_server.ps1 |
|---|---|---|
| 포트 | 127.0.0.1:8791 (사용 중이면 8791~8810 탐색) | +:8792 (LAN 바인딩, 최초 1회 관리자 urlacl 등록; 실패 시 127.0.0.1 폴백) |
| 역할 | PIE.html·mediapipe 자산 정적 서빙 (MIME: wasm/tflite/data/binarypb/pie 포함) | ST 누적 공유 API — GET/POST `/api/st`, CORS 허용, `st_store.json`에 병합 저장 |
| 보안 | 루트 탈출 방지(GetFullPath 검사), 404/500 | 경로 1개만 허용, OPTIONS 204 |
| 종료 | 창 닫으면 종료 | 창 닫으면 종료 |

---

## 7. 실행·설치·배포

- **표준 실행(중국)**: 폴더째 복사 → `PIE(중국).bat` (chcp 65001, PIE.html 존재 확인 후 서버 기동)
- **ST 공유 서버 PC**: `PIE_ST_server_시작.bat` 실행, 각 클라이언트는 설정>ST 누적 저장소>서버에 `http://<서버IP>:8792` 등록
- **설치 스크립트들(⚠ 전부 PIE.html 단일 복사 — 중국판에는 부적합)**:
  - setup.bat/install.vbs: 바탕화면에 복사 (구형, 원본 온라인판 잔재)
  - PIE_설치.ps1(한국어 GUI)/PIE_setup.ps1(한·영·베 GUI, 중국 Windows 폰트 폴백): `%LOCALAPPDATA%\PIE_WorkAnalysis` 설치 + HKCU 언인스톨 레지스트리 + PIE_제거.bat 복사
- **웹 배포**: push → GitHub Actions(pages.yml)가 **폴더 전체**를 Pages로 배포 → download.html에서 main.zip 다운로드. 레거시 Jekyll 빌드가 대용량 바이너리에서 실패해 Actions 방식으로 전환(커밋 d82d663). download.html의 최근 업데이트 표시는 api.github.com 호출(오프라인 현장이 아닌 다운로드 시점용)
- **원본 대비 차이**: GAS(구글시트) 연동 제거, MediaPipe 로컬화, ST 누적 백엔드 신설, 라이선스/시작 화면 ko/zh 토글

## 8. 라이선스

- 형식 `PIE-XXXX-XXXX-XXXX`(hex 12자리). `_pieLicCheck`가 오프라인 해시 검증, {year, month} 만료 반환 — 해당 월 말일까지 유효, 이후 LicenseScreen으로 회귀
- 활성 키는 `pie_license_key`에 저장, 기동 시마다 재검증(LicensedApp 12373)
- ⚠ 검증 로직·시크릿이 public 저장소의 PIE.html 안에 있으므로 **알고리즘 상세는 어떤 문서에도 기재하지 않는다** (노출 리스크 자체는 백로그 B에서 결정)

## 9. 다국어

- STRINGS(1042): ko 53키 / zh 52키(`tab_lineanalysis` 누락) / vi 53키(UI 노출 없음, 원본 잔재)
- 라이선스·시작 화면은 STRINGS와 별도의 내장 T 객체로 ko/zh 처리 (12281, 2324)
- **한국어 하드코딩 잔존 구역**: StepGuide 4단계 안내(2367~2373, '눠러' 오타 포함), 각종 alert/confirm(불러오기 실패 11043, MediaPipe 로딩 중 8656 등), 간트 안내문(12255) — zh 전수 커버리지는 미달 (백로그 C)
- PIE_가이드.html은 ko/zh/vi 3언어 섹션 구조(단, 언어별 섹션 구성 일치 여부 미검증)

## 10. 알아둘 설계 결정·이음새(seam)

1. **영상 비저장 원칙**: 세션/.wvas 어디에도 영상 바이너리를 넣지 않는다. 불러온 뒤 영상 재드롭 필요
2. **부품 ST DB는 모델 무관**(model-independent): 같은 부품·작업명이면 모델이 달라도 하나의 ST로 누적 — `_stPickBetter`의 "표본수 우선" 선택 방식이 부풀림을 방지
3. **세션 30개 캡**: lsSave가 메타 목록을 30개로 자르지만 본문 blob은 남음(백로그 P0-2)
4. **하드코딩 기본값**: 레이팅 100·여유율 15%·택트 60초·유휴 임계 0.5초·fps 30·세션 캡 30·사이클 캡 10
5. **beginnerMode 기본 ON**: 첫 사용자는 쉬운 라벨+StepGuide. 전문가 전환은 설정에서
6. **원본(온라인판) 잔재**: vi 사전, setup.bat/install.vbs, 'WVAS-report' PDF 파일명(11153), wvas_ 키 프리픽스(구명 Work Video Analysis System 추정), 가이드의 "온라인/오프라인 기능" 섹션
7. **file:// 실행 감지 없음**: file://로 직접 열어도 경고 없이 실행되다가 Pose에서만 실패 — README로만 안내
8. **브라우저 요구**: File System Access API(저장/불러오기·ST folder 모드)와 `AbortSignal.timeout`(1461) 때문에 Chrome/Edge 최신판 필요. StartupModal에 명시
