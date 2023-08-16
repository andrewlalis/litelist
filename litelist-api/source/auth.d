module auth;

import handy_httpd;
import handy_httpd.handlers.filtered_handler;
import std.json;

void handleLogin(ref HttpRequestContext ctx) {
    JSONValue resp = JSONValue(string[string].init);
    resp.object["token"] = "authtoken";
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

struct User {
    string username;
    string email;
    string passwordHash;
}

struct AuthContext {
    string token;
    User user;
}

class AuthContextHolder {
    private static AuthContextHolder instance;

    static getInstance() {
        if (!instance) instance = new AuthContextHolder();
        return instance;
    }

    static reset() {
        auto i = getInstance();
        i.authenticated = false;
        i.context = AuthContext.init;
    }

    static setContext(string token, User user) {
        auto i = getInstance();
        i.authenticated = true;
        i.context = AuthContext(token, user);
    }

    private bool authenticated;
    private AuthContext context;
}

class TokenFilter : HttpRequestFilter {
    immutable HEADER_NAME = "Authorization";
    
    void apply(ref HttpRequestContext ctx, FilterChain filterChain) {
        AuthContextHolder.reset();
        if (!ctx.request.hasHeader(HEADER_NAME)) {
            ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
            ctx.response.writeBodyString("Missing Authorization header.");
            return;
        }
        string authHeader = ctx.request.getHeader(HEADER_NAME);
        if (authHeader.length < 7 || authHeader[0 .. 7] != "Bearer ") {
            ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
            ctx.response.writeBodyString("Invalid bearer token authorization header.");
            return;
        }
        string rawToken = authHeader[7 .. $];

        // TODO: Validate token and fetch user.
        User user = User("bleh", "bleh@example.com", "faef9834rfe");

        AuthContextHolder.setContext(rawToken, user);
        filterChain.doFilter(ctx);
    }
}
