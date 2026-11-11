<%@ page pageEncoding="UTF-8" contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" isErrorPage="true" %>
<%@ include file="../WEB-INF/runtime.jsp" %>
<%@ include file="../WEB-INF/content-store.jsp" %>
<%
try {
    requireMethod(request, "POST");
    String mime = request.getContentType();
    if (mime == null || !"application/json".equalsIgnoreCase(mime.split(";", 2)[0].trim()))
        throw new ApiException(415, "application/json 요청이 필요합니다.");
    request.setCharacterEncoding("UTF-8");
    JsonObject body = readBody(request);
    synchronized (application) {
        writeJson(response, out, updateContent(application, body));
    }
} catch (Exception ex) { writeError(response, out, ex); }
%>
