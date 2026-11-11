<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>콘텐츠 관리 · NOVA BANK BMS</title>
  <link rel="icon" type="image/svg+xml" href="assets/banner-blue.svg">
  <link rel="stylesheet" href="assets/editor.css"><script src="assets/editor.js" defer></script>
</head>
<body>
<header><div class="brand">N<span>●</span>VA BANK <small>BMS</small></div><span class="local">로컬 샘플</span></header>
<main>
  <div class="intro"><p class="eyebrow">CONTENT MANAGER</p><h1>화면의 문구와 배너를 관리하세요</h1><p>저장한 콘텐츠는 연결된 서비스 화면을 새로고침하면 반영됩니다.</p></div>
  <div class="workspace">
    <aside><h2>관리 콘텐츠 <span id="item-count">8</span></h2><p>수정할 항목을 선택하세요.</p><nav id="content-list" aria-label="콘텐츠 항목"></nav><button id="reload" class="secondary" type="button">최신 콘텐츠 불러오기</button></aside>
    <section class="editor" aria-labelledby="editor-title">
      <div class="editor-heading"><div><span id="content-type" class="badge">콘텐츠</span><h2 id="editor-title">불러오는 중입니다</h2></div><span id="version">버전 —</span></div>
      <p id="content-key" class="key"></p>
      <form id="editor-form">
        <fieldset id="fields" disabled>
          <div id="text-fields"><label for="text-value">표시 문구</label><textarea id="text-value" rows="6" maxlength="2000"></textarea><p class="hint">1~2,000자. HTML 태그는 일반 텍스트로 표시됩니다.</p></div>
          <div id="image-fields" hidden><label for="image-value">배너 이미지</label><select id="image-value"><option value="/assets/banner-blue.svg">블루 · 당신의 일상에, 든든한 금융</option><option value="/assets/banner-mint.svg">민트 · 소중한 마음을 안전하게 전해요</option><option value="/assets/banner-violet.svg">바이올렛 · 한 걸음씩, 더 나은 내일로</option></select><label for="image-alt">이미지 대체 설명</label><input id="image-alt" type="text" maxlength="2000"><p class="hint">이미지 내용을 이해할 수 있도록 설명해 주세요.</p></div>
          <p id="template-hint" class="template" hidden>알림 변수 {name}, {amount}, {fee}를 각각 한 번씩 유지해 주세요.</p>
          <div class="preview"><span>미리보기</span><p id="text-preview"></p><img id="image-preview" alt="" hidden></div>
          <div class="actions"><button id="save" type="submit">변경사항 저장</button><span>기존 콘텐츠의 문구와 이미지만 수정할 수 있습니다.</span></div>
        </fieldset>
      </form>
      <p id="message" role="status" aria-live="polite"></p>
    </section>
  </div>
  <footer>실제 고객 데이터·금융 거래·알림 발송을 사용하지 않는 로컬 데모입니다.</footer>
</main>
</body>
</html>
