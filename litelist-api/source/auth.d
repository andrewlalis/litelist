module auth;

import handy_httpd;
import handy_httpd.handlers.filtered_handler;
import jwt.jwt;
import jwt.algorithms;
import slf4d;

import std.datetime;
import std.json;
import std.path;
import std.file;
import std.typecons;

import data;


void handleLogin(ref HttpRequestContext ctx) {
    JSONValue loginData = ctx.request.readBodyAsJson();
    if ("username" !in loginData.object || "password" !in loginData.object) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Invalid login request data. Expected username and password.");
        return;
    }
    string username = loginData.object["username"].str;
    infoF!"Got login request for user \"%s\"."(username);
    string password = loginData.object["password"].str;
    Nullable!User userNullable = userDataSource.getUser(username);
    if (userNullable.isNull) {
        infoF!"User \"%s\" doesn't exist."(username);
        sendUnauthenticatedResponse(ctx.response);
        return;
    }
    User user = userNullable.get();

    import botan.passhash.bcrypt : checkBcrypt;
    if (!checkBcrypt(password, user.passwordHash)) {
        sendUnauthenticatedResponse(ctx.response);
        return;
    }

    JSONValue resp = JSONValue(string[string].init);
    resp.object["token"] = generateToken(user);
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

void createNewUser(ref HttpRequestContext ctx) {
    JSONValue userData = ctx.request.readBodyAsJson();
    string username = userData.object["username"].str;
    string email = userData.object["email"].str;
    string password = userData.object["password"].str;

    if (!userDataSource.getUser(username).isNull) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Username is taken.");
        return;
    }

    import botan.passhash.bcrypt : generateBcrypt;
    import botan.rng.auto_rng;
    RandomNumberGenerator rng = new AutoSeededRNG();
    string passwordHash = generateBcrypt(password, rng, 12);
    
    userDataSource.createUser(username, email, passwordHash);
}

void getMyUser(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx)) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    JSONValue resp = JSONValue(string[string].init);
    resp.object["username"] = JSONValue(auth.user.username);
    resp.object["email"] = JSONValue(auth.user.email);
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

void deleteMyUser(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx)) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    userDataSource.deleteUser(auth.user.username);
}

private string generateToken(in User user) {
    Token token = new Token(JWTAlgorithm.HS512);
    token.claims.aud("litelist-api");
    token.claims.sub(user.username);
    token.claims.exp(Clock.currTime.toUnixTime() + 5000);
    token.claims.iss("litelist-api");
    return token.encode("supersecret");// TODO: Extract secret.
}

private void sendUnauthenticatedResponse(ref HttpResponse resp) {
    resp.setStatus(HttpStatus.UNAUTHORIZED);
    resp.writeBodyString("Invalid credentials.");
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

    static AuthContext getOrThrow() {
        auto i = getInstance();
        if (!i.authenticated) throw new HttpStatusException(HttpStatus.UNAUTHORIZED, "No authentication context.");
        return i.context;
    }

    private bool authenticated;
    private AuthContext context;
}

/**
 * Validates any request that should be authenticated with an access token,
 * and sets the AuthContextHolder's context if the user is authenticated.
 * Otherwise, sends an appropriate "unauthorized" response.
 * Params:
 *   ctx = The request context to validate.
 * Returns: True if the user is authenticated, or false otherwise.
 */
bool validateAuthenticatedRequest(ref HttpRequestContext ctx) {
    immutable HEADER_NAME = "Authorization";
    AuthContextHolder.reset();
    if (!ctx.request.hasHeader(HEADER_NAME)) {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("Missing Authorization header.");
        return false;
    }
    string authHeader = ctx.request.getHeader(HEADER_NAME);
    if (authHeader.length < 7 || authHeader[0 .. 7] != "Bearer ") {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("Invalid bearer token authorization header.");
        return false;
    }

    string rawToken = authHeader[7 .. $];
    string username;
    try {
        Token token = verify(rawToken, "supersecret", [JWTAlgorithm.HS512]);
        username = token.claims.sub;
    } catch (Exception e) {
        warn("Failed to verify user token.", e);
        throw new HttpStatusException(HttpStatus.UNAUTHORIZED, "Invalid token.");
    }

    Nullable!User user = userDataSource.getUser(username);
    if (user.isNull) {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("User does not exist.");
        return false;
    }

    AuthContextHolder.setContext(rawToken, user.get);
    return true;
}

class TokenFilter : HttpRequestFilter {
    void apply(ref HttpRequestContext ctx, FilterChain filterChain) {
        if (validateAuthenticatedRequest(ctx)) filterChain.doFilter(ctx);
    }
}
