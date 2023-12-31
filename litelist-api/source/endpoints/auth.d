/**
 * API endpoints related to authentication.
 */
module endpoints.auth;

import handy_httpd;
import slf4d;

import std.json;
import std.typecons;

import auth;
import data.user;

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
    resp.object["token"] = generateToken(user, loadTokenSecret());
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

void renewToken(ref HttpRequestContext ctx) {
    AuthContext auth = getAuthContextOrThrow(ctx);

    JSONValue resp = JSONValue(string[string].init);
    resp.object["token"] = generateToken(auth.user, loadTokenSecret());
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

void createNewUser(ref HttpRequestContext ctx) {
    import std.regex;

    JSONValue userData = ctx.request.readBodyAsJson();
    if ("username" !in userData.object || "email" !in userData.object || "password" !in userData.object) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Missing required data.");
        return;
    }

    string username = userData.object["username"].str;
    string email = userData.object["email"].str;
    string password = userData.object["password"].str;

    const ctr = ctRegex!(`^[a-zA-Z0-9][a-zA-Z0-9-_]{2,23}$`);
    Captures!string c = matchFirst(username, ctr);
    if (c.empty) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Invalid username.");
        return;
    }

    if (password.length < 8) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Password is too short. Should be at least 8 characters.");
        return;
    }

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
    infoF!"Created new user: %s, %s"(username, email);
}

void getMyUser(ref HttpRequestContext ctx) {
    AuthContext auth = getAuthContextOrThrow(ctx);
    JSONValue resp = JSONValue(string[string].init);
    resp.object["username"] = JSONValue(auth.user.username);
    resp.object["email"] = JSONValue(auth.user.email);
    resp.object["admin"] = JSONValue(auth.user.admin);
    ctx.response.writeBodyString(resp.toString(), "application/json");
}

void deleteMyUser(ref HttpRequestContext ctx) {
    AuthContext auth = getAuthContextOrThrow(ctx);
    userDataSource.deleteUser(auth.user.username);
}
