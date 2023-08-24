module data.note;

public import data.model : Note;

interface NoteDataSource {
    Note createNote(string username, ulong noteListId, string content);
    Note updateNote(string username, ulong id, Note newData);
    void deleteNote(string username, ulong id);
    ulong countNotes(string username);
    ulong countNotes(string username, ulong noteListId);
}

static NoteDataSource noteDataSource;
static this() {
    import data.impl.note;
    noteDataSource = new SqliteNoteDataSource();
}
