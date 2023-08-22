module data.list;

public import data.model : NoteList;

import std.typecons : Nullable;

interface NoteListDataSource {
    NoteList[] getLists(string username);
    Nullable!NoteList getList(string username, ulong id);
    NoteList createNoteList(string username, string name, string description = null);
    void deleteNoteList(string username, ulong id);
    NoteList updateNoteList(string username, ulong id, NoteList newData);
}

static NoteListDataSource noteListDataSource;
static this() {
    import data.impl.list;
    noteListDataSource = new SqliteNoteListDataSource();
}
