/**
 * PIE 부품 ST 누적 — 구글 시트 연동 스크립트
 * =====================================================================
 * 떨어진 지역(심양 · 비나 · 한국)끼리 부품별 표준시간(ST)을 공유할 때 씁니다.
 * 같은 공장 안에서만 공유하면 되면 이게 필요 없습니다 — 설정에서 "폴더"나 "서버"를 쓰세요.
 *
 * ── 설치 방법 (10분, 한 번만) ─────────────────────────────────────────
 *  1) 구글 드라이브에서 새 스프레드시트를 하나 만듭니다. 이름은 자유 (예: PIE_부품ST)
 *  2) 그 시트에서 메뉴 [확장 프로그램] → [Apps Script] 클릭
 *  3) 기본으로 들어 있는 코드를 모두 지우고, 이 파일 내용을 전부 붙여넣기
 *  4) 저장(💾) 후 오른쪽 위 [배포] → [새 배포] 클릭
 *  5) 유형 선택(톱니바퀴) → [웹 앱]
 *       - 설명      : PIE
 *       - 실행 계정 : 나
 *       - 액세스 권한: "링크가 있는 모든 사용자"      ← 꼭 이걸로
 *  6) [배포] → 권한 승인(처음 한 번) → 나오는 "웹 앱 URL" 복사
 *       https://script.google.com/macros/s/..../exec  모양입니다
 *  7) PIE 프로그램 → 설정(⚙️) → 부품 ST 누적 저장소 → [📊 구글 시트] → 주소 붙여넣기
 *     → [🔄 지금 동기화] 눌러 "✅ 동기화 성공" 이 뜨면 끝
 *
 *  ⚠ 코드를 고친 뒤에는 반드시 [배포] → [배포 관리] → 연필(수정) → [새 버전] 으로
 *     다시 배포해야 반영됩니다. 저장만 하면 주소는 옛 코드를 계속 씁니다.
 *  ⚠ 중국처럼 구글이 막힌 곳에서는 동작하지 않습니다. 그곳에서는 폴더/서버를 쓰세요.
 *
 * ── 만들어지는 시트 ──────────────────────────────────────────────────
 *   parts     부품 목록          (품번 · 품명 · 규격 · Maker 등)
 *   st        부품별 표준시간     (부품 · 작업명 · ST · 샘플수 · 갱신일시)
 *   tomb      삭제된 ST 기록      (지운 내용이 다른 PC에서 되살아나지 않게)
 *   partTomb  삭제된 부품 기록
 *   눈으로 확인하거나 엑셀로 내려받아 쓰셔도 됩니다. 단, 값을 직접 고치면
 *   다음 동기화 때 프로그램 쪽 내용으로 덮어써질 수 있습니다.
 * =====================================================================
 */

var PART_COLS = ['id','name','code','partName','spec','unit','qty','maker','makerPn','custPn','bomModel','createdAt'];

function _ss() { return SpreadsheetApp.getActiveSpreadsheet(); }

function _sheet(name, header) {
  var ss = _ss();
  var sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    sh.getRange(1, 1, 1, header.length).setValues([header]);
    sh.setFrozenRows(1);
  }
  return sh;
}

function _rows(sh) {
  var last = sh.getLastRow();
  if (last < 2) return [];
  return sh.getRange(2, 1, last - 1, sh.getLastColumn()).getValues();
}

function _write(sh, header, rows) {
  sh.clear();
  sh.getRange(1, 1, 1, header.length).setValues([header]);
  sh.setFrozenRows(1);
  if (rows.length) {
    sh.getRange(2, 1, rows.length, header.length).setValues(rows);
  }
}

/* ── 읽기: 시트 → PIE ────────────────────────────────────────────── */
function _read() {
  var out = { parts: [], partSt: {}, tomb: {}, partTomb: {} };

  _rows(_sheet('parts', PART_COLS)).forEach(function (r) {
    if (!r[0]) return;
    var p = {};
    PART_COLS.forEach(function (c, i) {
      var v = r[i];
      if (v !== '' && v !== null && v !== undefined) p[c] = (c === 'qty') ? Number(v) || 0 : String(v);
    });
    out.parts.push(p);
  });

  _rows(_sheet('st', ['partId', 'taskName', 'st', 'n', 'updatedAt'])).forEach(function (r) {
    if (!r[0] || !r[1]) return;
    var pid = String(r[0]), task = String(r[1]);
    if (!out.partSt[pid]) out.partSt[pid] = {};
    out.partSt[pid][task] = { st: Number(r[2]) || 0, n: Number(r[3]) || 0, updatedAt: String(r[4] || '') };
  });

  _rows(_sheet('tomb', ['partId', 'taskName', 'deletedAt'])).forEach(function (r) {
    if (!r[0] || !r[1]) return;
    var pid = String(r[0]);
    if (!out.tomb[pid]) out.tomb[pid] = {};
    out.tomb[pid][String(r[1])] = String(r[2] || '');
  });

  _rows(_sheet('partTomb', ['partName', 'deletedAt'])).forEach(function (r) {
    if (!r[0]) return;
    out.partTomb[String(r[0])] = String(r[1] || '');
  });

  return out;
}

/* ── 쓰기: PIE → 시트 ────────────────────────────────────────────── */
function _save(payload) {
  var parts = payload.parts || [];
  _write(_sheet('parts', PART_COLS), PART_COLS, parts.map(function (p) {
    return PART_COLS.map(function (c) { return p[c] === undefined || p[c] === null ? '' : p[c]; });
  }));

  var stRows = [];
  var partSt = payload.partSt || {};
  Object.keys(partSt).forEach(function (pid) {
    Object.keys(partSt[pid] || {}).forEach(function (task) {
      var d = partSt[pid][task] || {};
      stRows.push([pid, task, d.st || 0, d.n || 0, d.updatedAt || '']);
    });
  });
  _write(_sheet('st', ['partId', 'taskName', 'st', 'n', 'updatedAt']), ['partId', 'taskName', 'st', 'n', 'updatedAt'], stRows);

  var tombRows = [];
  var tomb = payload.tomb || {};
  Object.keys(tomb).forEach(function (pid) {
    Object.keys(tomb[pid] || {}).forEach(function (task) {
      tombRows.push([pid, task, tomb[pid][task] || '']);
    });
  });
  _write(_sheet('tomb', ['partId', 'taskName', 'deletedAt']), ['partId', 'taskName', 'deletedAt'], tombRows);

  var ptRows = [];
  var pt = payload.partTomb || {};
  Object.keys(pt).forEach(function (k) { ptRows.push([k, pt[k] || '']); });
  _write(_sheet('partTomb', ['partName', 'deletedAt']), ['partName', 'deletedAt'], ptRows);
}

/* ── 웹앱 진입점 ─────────────────────────────────────────────────── */
function _json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  try {
    return _json(_read());
  } catch (err) {
    return _json({ error: String(err) });
  }
}

function doPost(e) {
  var lock = LockService.getScriptLock();   // 두 PC가 동시에 올려도 섞이지 않게
  try {
    lock.waitLock(20000);
    var payload = JSON.parse(e.postData.contents);
    _save(payload);
    return _json({ ok: true, parts: (payload.parts || []).length });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  } finally {
    try { lock.releaseLock(); } catch (x) {}
  }
}
