module endpoints.admin;

import handy_httpd;
import slf4d;

import std.file;
import std.path;
import std.json;

void getAllUsers(ref HttpRequestContext ctx) {
    import data.impl.user;
    import data.list;
    import data.note;

    JSONValue usersArray = JSONValue(string[].init);

    foreach (DirEntry entry; dirEntries(USERS_DIR, SpanMode.shallow, false)) {
        string username = baseName(entry.name);
        JSONValue userData = parseJSON(readText(buildPath(USERS_DIR, username, DATA_FILE)));
        string email = userData.object["email"].str;
        bool admin = userData.object["admin"].boolean;
        ulong listCount = noteListDataSource.countLists(username);
        ulong noteCount = noteDataSource.countNotes(username);
        JSONValue userObj = JSONValue(string[string].init);
        userObj.object["username"] = JSONValue(username);
        userObj.object["email"] = JSONValue(email);
        userObj.object["admin"] = JSONValue(admin);
        userObj.object["listCount"] = JSONValue(listCount);
        userObj.object["noteCount"] = JSONValue(noteCount);
        usersArray.array ~= userObj;
    }
    ctx.response.writeBodyString(usersArray.toString(), "application/json");
}