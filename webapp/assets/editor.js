'use strict';
(() => {
  const labels = {
    'home.welcome': '고객 홈 환영 문구',
    'common.transfer.guide': '공통 이체 안내',
    'transfer.submit.label': '이체 버튼 문구',
    'transfer.fee.guide': '이체 수수료 안내',
    'notification.transfer.complete': '이체 완료 알림 양식',
    'notification.notice.guide': '공지 안내 문구',
    'home.hero.image': '고객 홈 메인 배너',
    'transfer.banner.image': '이체 안내 배너'
  };
  const allowedImages = new Set(['/assets/banner-blue.svg', '/assets/banner-mint.svg', '/assets/banner-violet.svg']);
  const el = id => document.getElementById(id);
  let content;
  let selected;
  let busy = false;

  function message(text, error = false) {
    el('message').textContent = text;
    el('message').classList.toggle('error', error);
  }

  async function api(path, options = {}) {
    const response = await fetch(path, {credentials: 'same-origin', cache: 'no-store', ...options});
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || '요청을 처리하지 못했습니다.');
    return result;
  }

  function preview() {
    const image = content.items[selected].type === 'image';
    el('text-preview').hidden = image;
    el('image-preview').hidden = !image;
    if (image) {
      const path = el('image-value').value;
      if (allowedImages.has(path)) el('image-preview').src = path;
      el('image-preview').alt = el('image-alt').value;
    } else {
      el('text-preview').textContent = el('text-value').value;
    }
  }

  function choose(key) {
    if (busy) return;
    selected = key;
    const item = content.items[key];
    const image = item.type === 'image';
    el('editor-title').textContent = labels[key] || key;
    el('content-key').textContent = key;
    el('content-type').textContent = image ? '이미지' : '텍스트';
    el('text-fields').hidden = image;
    el('image-fields').hidden = !image;
    el('template-hint').hidden = key !== 'notification.transfer.complete';
    el('text-value').value = image ? '' : item.value;
    el('image-value').value = image ? item.value : '/assets/banner-blue.svg';
    el('image-alt').value = item.alt || '';
    document.querySelectorAll('#content-list button').forEach(button => {
      const active = button.dataset.key === key;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    el('fields').disabled = false;
    message('');
    preview();
  }

  function render() {
    el('version').textContent = `버전 ${content.version}`;
    el('item-count').textContent = String(Object.keys(content.items).length);
    el('content-list').replaceChildren();
    for (const key of Object.keys(content.items)) {
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.key = key;
      button.textContent = labels[key] || key;
      const code = document.createElement('small');
      code.textContent = key;
      button.append(code);
      button.addEventListener('click', () => choose(key));
      el('content-list').append(button);
    }
    choose(content.items[selected] ? selected : Object.keys(content.items)[0]);
  }

  async function load() {
    if (busy) return;
    busy = true;
    el('fields').disabled = true;
    el('reload').disabled = true;
    message('최신 콘텐츠를 불러오는 중입니다.');
    try {
      content = await api('api/content.jsp');
      busy = false;
      render();
    } catch (error) {
      message(error.message || '콘텐츠를 불러오지 못했습니다.', true);
    } finally {
      busy = false;
      el('reload').disabled = false;
    }
  }

  el('editor-form').addEventListener('submit', async event => {
    event.preventDefault();
    if (busy || !selected) return;
    const image = content.items[selected].type === 'image';
    const body = {key: selected, value: image ? el('image-value').value : el('text-value').value};
    if (image) body.alt = el('image-alt').value;
    busy = true;
    el('fields').disabled = true;
    el('reload').disabled = true;
    message('저장하는 중입니다.');
    try {
      content = await api('api/update.jsp', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)});
      busy = false;
      render();
      message('저장했습니다. 연결된 화면을 새로고침해 확인하세요.');
    } catch (error) {
      message(error.message || '저장하지 못했습니다.', true);
    } finally {
      busy = false;
      el('fields').disabled = false;
      el('reload').disabled = false;
    }
  });
  el('reload').addEventListener('click', load);
  ['text-value', 'image-value', 'image-alt'].forEach(id => el(id).addEventListener('input', preview));
  load();
})();
