/**
 * Logic for user authentication.
 */
module auth;

import handy_httpd;
import handy_httpd.handlers.filtered_handler;
import slf4d;

import std.typecons;

import data.user;

immutable string AUTH_METADATA_KEY = "AuthContext";

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
    return token.encode(secret);
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

class AuthContext {
    string token;
    User user;

    this(string token, User user) {
        this.token = token;
        this.user = user;
    }
}

/**
 * Validates any request that should be authenticated with an access token,
 * and sets the AuthContextHolder's context if the user is authenticated.
 * Otherwise, sends an appropriate "unauthorized" response.
 * Params:
 *   ctx = The request context to validate.
 *   secret = The secret key that should have been used to sign the token.
 * Returns: The AuthContext if authentication is successful, or null otherwise.
 */
Nullable!AuthContext validateAuthenticatedRequest(ref HttpRequestContext ctx, in string secret) {
    import jwt.jwt : verify, Token;
    import jwt.algorithms : JWTAlgorithm;
    import std.typecons;

    immutable HEADER_NAME = "Authorization";
    if (!ctx.request.headers.contains(HEADER_NAME)) {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("Missing Authorization header.");
        return Nullable!AuthContext.init;
    }
    string authHeader = ctx.request.headers.getFirst(HEADER_NAME).orElse("");
    if (authHeader.length < 7 || authHeader[0 .. 7] != "Bearer ") {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("Invalid bearer token authorization header.");
        return Nullable!AuthContext.init;
    }

    string rawToken = authHeader[7 .. $];
    string username;
    try {
        Token token = verify(rawToken, secret, [JWTAlgorithm.HS512]);
        username = token.claims.sub;
    } catch (Exception e) {
        warn("Failed to verify user token.", e);
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("Invalid or malformed token.");
        return Nullable!AuthContext.init;
    }

    Nullable!User user = userDataSource.getUser(username);
    if (user.isNull) {
        ctx.response.setStatus(HttpStatus.UNAUTHORIZED);
        ctx.response.writeBodyString("User does not exist.");
        return Nullable!AuthContext.init;
    }

    return nullable(new AuthContext(rawToken, user.get));
}

class TokenFilter : HttpRequestFilter {
    private immutable string secret;

    this(string secret) {
        this.secret = secret;
    }

    void apply(ref HttpRequestContext ctx, FilterChain filterChain) {
        Nullable!AuthContext optionalAuth = validateAuthenticatedRequest(ctx, this.secret);
        if (!optionalAuth.isNull) {
            ctx.metadata[AUTH_METADATA_KEY] = optionalAuth.get();
            filterChain.doFilter(ctx); // Only continue the filter chain if we're authenticated.
        }
    }
}

class AdminFilter : HttpRequestFilter {
    void apply(ref HttpRequestContext ctx, FilterChain filterChain) {
        AuthContext authCtx = getAuthContextOrThrow(ctx);
        if (authCtx.user.admin) {
            filterChain.doFilter(ctx);
        } else {
            ctx.response.setStatus(HttpStatus.FORBIDDEN);
        }
    }
}

AuthContext getAuthContextOrThrow(ref HttpRequestContext ctx) {
    if (AUTH_METADATA_KEY in ctx.metadata) {
        if (auto authCtx = cast(AuthContext) ctx.metadata[AUTH_METADATA_KEY]) {
            return authCtx;
        }
    }
    throw new HttpStatusException(HttpStatus.UNAUTHORIZED, "Not authenticated.");
}
