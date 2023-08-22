/**
 * Logic for user authentication.
 */
module auth;

import handy_httpd;
import handy_httpd.handlers.filtered_handler;
import slf4d;

import data.user;

/**
 * Generates a new access token for an authenticated user.
 * Params:
 *   user = The user to generate a token for.
 *   secret = The secret key to use to sign the token.
 * Returns: The base-64 encoded and signed token string.
 */
string generateToken(in User user, in string secret) {
    import jwt.jwt : Token;
    import jwt.algorithms : JWTAlgorithm;
    import std.datetime;
    Token token = new Token(JWTAlgorithm.HS512);
    token.claims.aud("litelist-api");
    token.claims.sub(user.username);
    token.claims.exp(Clock.currTime.toUnixTime() + 5000);
    token.claims.iss("litelist-api");
    return token.encode("supersecret");// TODO: Extract secret.
}

void sendUnauthenticatedResponse(ref HttpResponse resp) {
    resp.setStatus(HttpStatus.UNAUTHORIZED);
    resp.writeBodyString("Invalid credentials.");
}

string loadTokenSecret() {
    import std.file : exists;
    import d_properties;
    if (exists("application.properties")) {
        Properties props = Properties("application.properties");
        if (props.has("secret")) {
            return props.get("secret");
        }
    }
    error("Couldn't load token secret from application.properties. Using insecure secret.");
    return "supersecret";
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
 *   secret = The secret key that should have been used to sign the token.
 * Returns: True if the user is authenticated, or false otherwise.
 */
bool validateAuthenticatedRequest(ref HttpRequestContext ctx, in string secret) {
    import jwt.jwt : verify, Token;
    import jwt.algorithms : JWTAlgorithm;
    import std.typecons;

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
    private immutable string secret;

    this(string secret) {
        this.secret = secret;
    }

    void apply(ref HttpRequestContext ctx, FilterChain filterChain) {
        if (validateAuthenticatedRequest(ctx, this.secret)) filterChain.doFilter(ctx);
    }
}
