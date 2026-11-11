"""Real HTTP contract tests; restore editable values after each mutation."""
import concurrent.futures
import json
import os
from pathlib import Path
import unittest
import urllib.error
import urllib.request

BASE = os.environ.get("BMS_URL", "http://127.0.0.1:18085").rstrip("/")
DATA = Path(os.environ.get("BMS_DATA_FILE", Path(__file__).resolve().parents[1] / ".runtime/content.json"))
KEYS = {"home.welcome", "common.transfer.guide", "transfer.submit.label", "transfer.fee.guide", "notification.transfer.complete", "notification.notice.guide", "home.hero.image", "transfer.banner.image", "product.guide", "product.hero.image", "mypage.notice"}
ASSETS = ["/assets/banner-blue.svg", "/assets/banner-mint.svg", "/assets/banner-violet.svg"]


def request(path, method="GET", body=None, content_type="application/json", raw=False):
    data = body.encode() if raw else json.dumps(body, ensure_ascii=False).encode() if body is not None else None
    headers = {"Content-Type": content_type} if content_type else {}
    req = urllib.request.Request(BASE + path, data=data, method=method, headers=headers)
    try:
        response = urllib.request.urlopen(req, timeout=20)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        raw = response.read().decode("utf-8")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = raw[:300]
        return response.status, payload, response.headers


class BmsHttpTests(unittest.TestCase):
    def content(self):
        status, value, headers = request("/api/content.jsp")
        self.assertEqual(status, 200, value)
        self.assertEqual(headers.get("Cache-Control"), "no-store")
        self.assertIn("application/json", headers.get("Content-Type", ""))
        return value

    def update(self, key, value, alt=None):
        body = {"key": key, "value": value}
        if alt is not None:
            body["alt"] = alt
        status, result, _ = request("/api/update.jsp", "POST", body)
        self.assertEqual(status, 200, result)
        return result

    def restore(self, items):
        for key, item in items.items():
            self.update(key, item["value"], item.get("alt"))

    def test_content_has_required_text_and_image_items(self):
        content = self.content()
        self.assertIs(type(content["version"]), int)
        self.assertGreaterEqual(content["version"], 1)
        self.assertEqual(set(content["items"]), KEYS)
        for key, item in content["items"].items():
            self.assertEqual(item["type"], "image" if key.endswith(".image") else "text")
            self.assertIsInstance(item["value"], str)
            self.assertTrue(item["value"].strip())
            if item["type"] == "image":
                self.assertIn(item["value"], ASSETS)
                self.assertTrue(item["alt"].strip())

    def test_text_and_image_updates_are_visible_and_persisted_with_versions(self):
        before = self.content()
        keys = ["home.welcome", "home.hero.image"]
        try:
            updated = self.update(keys[0], "테스트 문구 <script>alert(1)</script>")
            self.assertEqual(updated["version"], before["version"] + 1)
            self.assertEqual(updated["items"][keys[0]]["value"], "테스트 문구 <script>alert(1)</script>")
            updated = self.update(keys[1], ASSETS[1], "민트색 테스트 배너")
            self.assertEqual(updated["version"], before["version"] + 2)
            self.assertEqual(updated["items"][keys[1]]["alt"], "민트색 테스트 배너")
            self.assertEqual(self.content(), updated)
            self.assertEqual(json.loads(DATA.read_text()), updated)
        finally:
            self.restore({key: before["items"][key] for key in keys})

    def test_concurrent_updates_do_not_lose_changes_or_versions(self):
        before = self.content()
        changes = {"home.welcome": "동시 수정 대시보드", "common.transfer.guide": "동시 수정 공통 가이드", "transfer.submit.label": "동시 수정 버튼", "transfer.fee.guide": "동시 수정 수수료"}
        try:
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                results = list(pool.map(lambda pair: self.update(*pair), changes.items()))
            self.assertEqual(sorted(result["version"] for result in results), list(range(before["version"] + 1, before["version"] + 5)))
            current = self.content()
            for key, value in changes.items():
                self.assertEqual(current["items"][key]["value"], value)
            self.assertEqual(current["version"], before["version"] + 4)
        finally:
            self.restore({key: before["items"][key] for key in changes})

    def test_rejects_invalid_keys_types_empty_text_and_image_paths(self):
        before = self.content()
        bodies = [
            {"key": "new.key", "value": "생성 금지"},
            {"key": 42, "value": "문구"},
            {"key": "home.welcome", "value": 4},
            {"key": "home.welcome", "value": None},
            {"key": "home.welcome", "value": {}},
            {"key": "home.welcome", "value": "  \n"},
            {"key": "home.welcome", "value": "가" * 2001},
            {"key": "home.hero.image", "value": ASSETS[0]},
            {"key": "home.hero.image", "value": ASSETS[0], "alt": " "},
            {"key": "home.hero.image", "value": ASSETS[0], "alt": False},
            {"key": "home.hero.image", "value": ASSETS[0], "alt": "가" * 2001},
            {"key": "home.hero.image", "value": "/assets/../WEB-INF/data/content.json", "alt": "배너"},
            {"key": "home.hero.image", "value": "https://example.com/image.svg", "alt": "배너"},
            {"key": "home.hero.image", "value": "/assets/banner-blue.svg?x=1", "alt": "배너"},
            {"key": "home.hero.image", "value": "/assets/unknown.svg", "alt": "배너"},
        ]
        for body in bodies:
            with self.subTest(body=body):
                status, error, _ = request("/api/update.jsp", "POST", body)
                self.assertIn(status, (400, 404), error)
                self.assertIsInstance(error.get("error"), str)
        self.assertEqual(self.content(), before)

    def test_template_requires_exact_supported_placeholders(self):
        key = "notification.transfer.complete"
        before = self.content()
        try:
            valid = "안녕하세요 {name}님, {amount}원 이체 완료 (수수료 {fee}원)"
            self.assertEqual(self.update(key, valid)["items"][key]["value"], valid)
            for template in ("{name} {amount}", "{name} {amount} {fee} {other}", "{name} {amount} {fee} {name}", "{name} {amount} {fee} {", "{name} {amount} {fee} {}"):
                with self.subTest(template=template):
                    status, error, _ = request("/api/update.jsp", "POST", {"key": key, "value": template})
                    self.assertEqual(status, 400, error)
        finally:
            self.restore({key: before["items"][key]})

    def test_methods_and_non_json_browser_posts_are_rejected(self):
        before = self.content()
        for path, method, expected in [("/api/content.jsp", "POST", 405), ("/api/update.jsp", "GET", 405)] + [(path, method, 405) for path in ("/api/content.jsp", "/api/update.jsp") for method in ("PUT", "DELETE", "OPTIONS")]:
            status, error, _ = request(path, method)
            self.assertEqual(status, expected, error)
            self.assertIsInstance(error, dict)
            self.assertIsInstance(error.get("error"), str)
        body = {"key": "home.welcome", "value": "차단되어야 하는 변경"}
        for content_type in ("text/plain", "application/x-www-form-urlencoded", "multipart/form-data; boundary=x", "application/json-evil"):
            with self.subTest(content_type=content_type):
                status, error, _ = request("/api/update.jsp", "POST", body, content_type)
                self.assertEqual(status, 415, error)
        for bad_body in ([], "text", None):
            status, error, _ = request("/api/update.jsp", "POST", bad_body)
            self.assertEqual(status, 400, error)
        self.assertEqual(self.content(), before)

    def test_bundled_images_are_accessible(self):
        for path in ASSETS:
            with urllib.request.urlopen(BASE + path, timeout=10) as response:
                self.assertEqual(response.status, 200)
                self.assertIn("image/svg+xml", response.headers.get("Content-Type", ""))
                self.assertIn(b"<svg", response.read())

    def test_nonstandard_or_malformed_json_is_rejected(self):
        for raw in ("{key:'nonexistent-review-key',value:'rejected'}", '{"key":"nonexistent-review-key","value":"rejected"} trailing', ''):
            with self.subTest(raw=raw):
                status, error, _ = request("/api/update.jsp", "POST", raw, raw=True)
                self.assertEqual(status, 400, error)
                self.assertIsInstance(error.get("error"), str)

    def test_editor_page_is_available(self):
        with urllib.request.urlopen(BASE + "/", timeout=10) as response:
            self.assertEqual(response.status, 200)
            self.assertIn("text/html", response.headers.get("Content-Type", ""))


if __name__ == "__main__":
    unittest.main()
