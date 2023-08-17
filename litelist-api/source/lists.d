module lists;

import handy_httpd;
import std.json;

import auth;
import data;

void getNoteLists(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx)) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    NoteList[] lists = userDataSource.getLists(auth.user.username);
    JSONValue listsArray = JSONValue(string[].init);
    foreach (NoteList list; lists) {
        listsArray.array ~= serializeList(list);
    }
    ctx.response.writeBodyString(listsArray.toString(), "application/json");
}

void createNoteList(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx)) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    JSONValue requestBody = ctx.request.readBodyAsJson();
    string listName = requestBody.object["name"].str;
    string description = requestBody.object["description"].str;
    NoteList list = userDataSource.createNoteList(auth.user.username, listName, description);
    ctx.response.writeBodyString(serializeList(list).toString(), "application/json");
}

void deleteNoteList(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx)) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    userDataSource.deleteNoteList(auth.user.username, ctx.request.getPathParamAs!ulong("id"));
}

private JSONValue serializeList(NoteList list) {
    JSONValue listObj = JSONValue(string[string].init);
    listObj.object["id"] = JSONValue(list.id);
    listObj.object["name"] = JSONValue(list.name);
    listObj.object["ordinality"] = JSONValue(list.ordinality);
    listObj.object["description"] = JSONValue(list.description);
    listObj.object["notes"] = JSONValue(string[].init);
    foreach (Note note; list.notes) {
        listObj.object["notes"].array ~= serializeNote(note);
    }
    return listObj;
}

private JSONValue serializeNote(Note note) {
    JSONValue noteObj = JSONValue(string[string].init);
    noteObj.object["id"] = JSONValue(note.id);
    noteObj.object["ordinality"] = JSONValue(note.ordinality);
    noteObj.object["noteListId"] = JSONValue(note.noteListId);
    noteObj.object["content"] = JSONValue(note.content);
    return noteObj;
}
