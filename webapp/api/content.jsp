<%@ page pageEncoding="UTF-8" contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" isErrorPage="true" %>
<%@ include file="../WEB-INF/runtime.jsp" %>
<%@ include file="../WEB-INF/content-store.jsp" %>
<%
try {
    requireMethod(request, "GET");
    synchronized (application) {
        writeJson(response, out, loadContent(application));
    }
} catch (Exception ex) { writeError(response, out, ex); }
%>
