<%@ page pageEncoding="UTF-8" %>
<%!
    private static final Set<String> BMS_IMAGES = Set.of(
        "/assets/banner-blue.svg", "/assets/banner-mint.svg", "/assets/banner-violet.svg");

    private Path contentFile() {
        return Path.of(env("DATA_DIR", System.getProperty("java.io.tmpdir") + "/bank-bms-data"), "content.json");
    }

    // Callers hold the shared servlet-context lock through read, change and write.
    private JsonObject loadContent(javax.servlet.ServletContext context) throws IOException {
        Path file = contentFile();
        if (!Files.exists(file)) {
            try (InputStream seed = context.getResourceAsStream("/WEB-INF/data/content.json")) {
                if (seed == null) throw new IOException("Missing content seed");
                JsonObject initial = JsonParser.parseString(new String(seed.readAllBytes(), StandardCharsets.UTF_8)).getAsJsonObject();
                saveContent(initial);
            }
        }
        return JsonParser.parseString(Files.readString(file, StandardCharsets.UTF_8)).getAsJsonObject();
    }

    private void saveContent(JsonObject content) throws IOException {
        Path file = contentFile();
        Files.createDirectories(file.getParent());
        Path temporary = Files.createTempFile(file.getParent(), "content-", ".json.tmp");
        try {
            Files.writeString(temporary, GSON.toJson(content), StandardCharsets.UTF_8);
            // These public demo texts must remain readable from a bind-mounted data directory.
            if (!temporary.toFile().setReadable(true, false)) throw new IOException("Cannot set content read permissions");
            Files.move(temporary, file, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
        } finally {
            Files.deleteIfExists(temporary);
        }
    }

    private String checkedText(JsonObject body, String key) {
        String value = stringValue(body, key);
        if (value.isBlank() || value.length() > 2000)
            throw new ApiException(400, key + " 값은 공백을 제외한 1자 이상, 2,000자 이하여야 합니다.");
        return value;
    }

    private void checkTemplate(String value) {
        String remaining = value;
        for (String token : List.of("{name}", "{amount}", "{fee}")) {
            int first = remaining.indexOf(token);
            if (first < 0 || remaining.indexOf(token, first + token.length()) >= 0)
                throw new ApiException(400, "알림 문구에는 {name}, {amount}, {fee}를 각각 한 번씩 넣어 주세요.");
            remaining = remaining.replace(token, "");
        }
        if (remaining.indexOf('{') >= 0 || remaining.indexOf('}') >= 0)
            throw new ApiException(400, "알림 문구에는 {name}, {amount}, {fee} 변수만 사용할 수 있습니다.");
    }

    private JsonObject updateContent(javax.servlet.ServletContext context, JsonObject body) throws IOException {
        String key = stringValue(body, "key");
        String value = checkedText(body, "value");
        String alt = body.has("alt") ? checkedText(body, "alt") : null;
        JsonObject content = loadContent(context);
        JsonObject items = content.getAsJsonObject("items");
        if (!items.has(key)) throw new ApiException(404, "등록된 콘텐츠 키가 아닙니다.");
        JsonObject item = items.getAsJsonObject(key);
        if ("image".equals(item.get("type").getAsString())) {
            if (!BMS_IMAGES.contains(value)) throw new ApiException(400, "제공된 배너 이미지만 선택할 수 있습니다.");
            if (alt == null) throw new ApiException(400, "이미지 대체 설명이 필요합니다.");
            item.addProperty("alt", alt);
        }
        if ("notification.transfer.complete".equals(key)) checkTemplate(value);
        item.addProperty("value", value);
        content.addProperty("version", Math.addExact(content.get("version").getAsLong(), 1));
        saveContent(content);
        return content;
    }
%>
