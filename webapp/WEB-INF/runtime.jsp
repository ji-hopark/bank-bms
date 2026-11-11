<%@ page pageEncoding="UTF-8" import="java.util.*,java.io.*,java.net.*,java.nio.charset.StandardCharsets,java.nio.file.*,com.google.gson.*,javax.servlet.http.*,javax.servlet.jsp.JspWriter" %>
<%!
    private static final Gson GSON = new GsonBuilder().setStrictness(Strictness.STRICT).serializeNulls().disableHtmlEscaping().setPrettyPrinting().create();
    private static class ApiException extends RuntimeException {
        final int status;
        ApiException(int status, String message) { super(message); this.status=status; }
    }
    private String env(String name, String fallback) {
        String value=System.getenv(name); return value==null || value.isBlank() ? fallback : value;
    }
    private String encode(String value) { return URLEncoder.encode(value, StandardCharsets.UTF_8); }
    private void requireMethod(HttpServletRequest req, String method) {
        if (!method.equals(req.getMethod())) throw new ApiException(405, method+" 요청만 지원합니다.");
    }
    private JsonObject readBody(HttpServletRequest req) throws IOException {
        req.setCharacterEncoding("UTF-8");
        if (req.getContentType()==null || !req.getContentType().toLowerCase(Locale.ROOT).startsWith("application/json"))
            throw new ApiException(415,"application/json 요청이 필요합니다.");
        StringBuilder text=new StringBuilder(); char[] buffer=new char[2048]; int n;
        while ((n=req.getReader().read(buffer))!=-1) {
            text.append(buffer,0,n); if(text.length()>65536) throw new ApiException(413,"요청이 너무 큽니다.");
        }
        try {
            JsonElement value=GSON.fromJson(text.toString(),JsonElement.class);
            if(value==null || !value.isJsonObject()) throw new ApiException(400,"JSON 객체가 필요합니다.");
            return value.getAsJsonObject();
        } catch (JsonParseException | IllegalStateException ex) { throw new ApiException(400,"올바른 JSON 객체가 필요합니다."); }
    }
    private String stringValue(JsonObject obj,String key) {
        JsonElement value=obj.get(key);
        if(value==null || !value.isJsonPrimitive() || !value.getAsJsonPrimitive().isString()) throw new ApiException(400,key+" 문자열이 필요합니다.");
        return value.getAsString();
    }
    private void writeJson(HttpServletResponse res,JspWriter writer,Object value) throws IOException {
        res.setHeader("Cache-Control","no-store"); res.setHeader("X-Content-Type-Options","nosniff");
        writer.print(GSON.toJson(value));
    }
    private void writeError(HttpServletResponse res,JspWriter writer,Exception ex) throws IOException {
        int status=ex instanceof ApiException ? ((ApiException)ex).status : ex instanceof IOException ? 502 : 400;
        res.setStatus(status);
        writeJson(res,writer,Map.of("error",status==502 ? "연계 서비스에 연결할 수 없습니다." : (ex.getMessage()==null ? "요청을 확인해 주세요." : ex.getMessage())));
    }
    private JsonObject getJson(String service,String path) throws IOException {
        String fallback="http://bank-"+service.toLowerCase(Locale.ROOT)+":8080";
        URL url=URI.create(env(service.toUpperCase(Locale.ROOT)+"_URL",fallback)+path).toURL();
        HttpURLConnection conn=(HttpURLConnection)url.openConnection();
        conn.setConnectTimeout(2500);conn.setReadTimeout(4000);conn.setRequestProperty("Accept","application/json");
        try {
            int status=conn.getResponseCode();
            if(status!=200) {
                if(status>=400 && status<500) {
                    String message="연계 조회 조건을 확인해 주세요.";
                    try(InputStream body=conn.getErrorStream()) {
                        if(body!=null) { JsonObject error=JsonParser.parseString(new String(body.readAllBytes(),StandardCharsets.UTF_8)).getAsJsonObject(); if(error.has("error")) message=error.get("error").getAsString(); }
                    } catch(Exception ignored) {}
                    throw new ApiException(status,message);
                }
                throw new IOException("Upstream "+service+" HTTP "+status);
            }
            try(InputStream body=conn.getInputStream()) {
                return JsonParser.parseString(new String(body.readAllBytes(),StandardCharsets.UTF_8)).getAsJsonObject();
            } catch(JsonParseException | IllegalStateException ex) { throw new IOException("Invalid upstream JSON",ex); }
        } finally { conn.disconnect(); }
    }
    private long positiveAmount(String raw) {
        if(raw==null || !raw.matches("[0-9]{1,9}")) throw new ApiException(400,"금액은 1원부터 999,999,999원까지의 정수입니다.");
        long value=Long.parseLong(raw);if(value<1) throw new ApiException(400,"금액은 1원 이상이어야 합니다.");return value;
    }
%>
