module data.impl.sqlite3_helpers;

import d2sqlite3;
import data.model;

import std.file;
import std.path;

NoteList parseNoteList(Row row) {
    NoteList list;
    list.id = row["id"].as!ulong;
    list.name = row["name"].as!string;
    list.ordinality = row["ordinality"].as!uint;
    list.description = row["description"].as!string;
    return list;
}

Note parseNote(Row row) {
    Note note;
    note.id = row["id"].as!ulong;
    note.noteListId = row["note_list_id"].as!ulong;
    note.ordinality = row["ordinality"].as!uint;
    note.content = row["content"].as!string;
    return note;
}

Database getDb(string username) {
    import data.impl.user : USERS_DIR, DB_FILE;
    string dbPath = buildPath(USERS_DIR, username, DB_FILE);
    if (!exists(dbPath)) initDb(dbPath);
    return Database(dbPath);
}

void initDb(string path) {
    if (exists(path)) std.file.remove(path);
    Database db = Database(path);
    db.run(q"SQL
        CREATE TABLE note_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            ordinality INTEGER NOT NULL DEFAULT 0,
            description TEXT NULL
        );

        CREATE TABLE note (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            note_list_id INTEGER NOT NULL,
            ordinality INTEGER NOT NULL DEFAULT 0,
            content TEXT NOT NULL
        );
SQL"
    );
    db.close();
}