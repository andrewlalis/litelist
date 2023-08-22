module endpoints.lists;

import handy_httpd;

import std.json;
import std.typecons;
import std.string;

import auth;
import data.list;
import data.note;

void getNoteLists(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    NoteList[] lists = noteListDataSource.getLists(auth.user.username);
    JSONValue listsArray = JSONValue(string[].init);
    foreach (NoteList list; lists) {
        listsArray.array ~= serializeList(list);
    }
    ctx.response.writeBodyString(listsArray.toString(), "application/json");
}

void getNoteList(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    ulong id = ctx.request.getPathParamAs!ulong("id");
    Nullable!NoteList optionalList = noteListDataSource.getList(auth.user.username, id);
    if (!optionalList.isNull) {
        ctx.response.writeBodyString(serializeList(optionalList.get()).toString(), "application/json");
    } else {
        ctx.response.setStatus(HttpStatus.NOT_FOUND);
    }
}

void createNoteList(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    JSONValue requestBody = ctx.request.readBodyAsJson();
    if ("name" !in requestBody.object) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Missing required name for creating a new list.");
        return;
    }
    string listName = strip(requestBody.object["name"].str);
    if (listName.length < 3) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("List name is too short. Should be at least 3 characters.");
    }
    string description = null;
    if ("description" in requestBody.object) {
        description = strip(requestBody.object["description"].str);
    }
    NoteList list = noteListDataSource.createNoteList(auth.user.username, listName, description);
    ctx.response.writeBodyString(serializeList(list).toString(), "application/json");
}

void createNote(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    ulong listId = ctx.request.getPathParamAs!ulong("listId");
    JSONValue requestBody = ctx.request.readBodyAsJson();
    if (
        "content" !in requestBody ||
        requestBody.object["content"].type != JSONType.STRING ||
        requestBody.object["content"].str.length < 1
    ) {
        ctx.response.setStatus(HttpStatus.BAD_REQUEST);
        ctx.response.writeBodyString("Missing string content.");
        return;
    }
    string content = requestBody.object["content"].str;
    Note note = noteDataSource.createNote(auth.user.username, listId, content);
    ctx.response.writeBodyString(serializeNote(note).toString(), "application/json");
}

void deleteNoteList(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    noteListDataSource.deleteNoteList(auth.user.username, ctx.request.getPathParamAs!ulong("id"));
}

void deleteNote(ref HttpRequestContext ctx) {
    if (!validateAuthenticatedRequest(ctx, loadTokenSecret())) return;
    AuthContext auth = AuthContextHolder.getOrThrow();
    ulong noteId = ctx.request.getPathParamAs!ulong("noteId");
    noteDataSource.deleteNote(auth.user.username, noteId);
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