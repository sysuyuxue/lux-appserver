package lux.appserver;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.servlet.ServletHandler;

public class AppHandler extends ServletHandler {
    
    @Override
    public void doHandle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
    {
        if (request.getRequestURI().matches(".*\\.xq.*")) {
            getServlet (AppServer.LUX_APP_FORWARDER).handle(baseRequest, request, response);
        } else {
            getServlet (AppServer.DEFAULT).handle(baseRequest, request, response);
        }
        baseRequest.setHandled(true);
    }
    
    @Override
    public void doScope(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException
    {
        if (request.getRequestURI().startsWith ("/solr")) {
            super.doScope(target, baseRequest, request, response);
        } else {
            // bypass the normal processing of filter and servlet matches
            doHandle (target, baseRequest, request, response);
        }
    }
}