module data.impl.note;

import data.model : Note;
import data.note;
import d2sqlite3;
import data.impl.sqlite3_helpers;
import handy_httpd;

import std.typecons;

class SqliteNoteDataSource : NoteDataSource {
    Note createNote(string username, ulong noteListId, string content) {
        Database db = getDb(username);
        
        Statement ordStmt = db.prepare("SELECT MAX(ordinality) + 1 FROM note WHERE note_list_id = ?");
        ordStmt.bind(1, noteListId);
        Nullable!uint ordResult = ordStmt.execute().oneValue!(Nullable!uint);
        uint ordinality = 0;
        if (!ordResult.isNull) ordinality = ordResult.get();

        Statement insertStmt = db.prepare("INSERT INTO note (note_list_id, ordinality, content) VALUES (?, ?, ?)");
        insertStmt.bind(1, noteListId);
        insertStmt.bind(2, ordinality);
        insertStmt.bind(3, content);
        insertStmt.execute();
        return Note(
            db.lastInsertRowid(),
            noteListId,
            ordinality,
            content
        );
    }

    Note updateNote(string username, ulong id, Note newData) {
        Database db = getDb(username);
        ResultRange result = db.execute("SELECT * FROM note WHERE id = ?", id);
        if (result.empty()) throw new HttpStatusException(HttpStatus.NOT_FOUND);
        Note note = parseNote(result.front());
        db.begin();
        if (note.ordinality != newData.ordinality) {
            if (newData.ordinality > note.ordinality) {
                // Decrement all notes between the old index and the new one.
                db.execute(
                    "UPDATE note SET ordinality = ordinality - 1 WHERE ordinality > ? AND ordinality <= ? AND note_list_id = ?",
                    note.ordinality,
                    newData.ordinality,
                    note.noteListId
                );
            } else {
                // Increment all notes between the old index and the new one.
                db.execute(
                    "UPDATE note SET ordinality = ordinality + 1 WHERE ordinality >= ? AND ordinality < ? AND note_list_id = ?",
                    newData.ordinality,
                    note.ordinality,
                    note.noteListId
                );
            }
        }
        db.execute(
            "UPDATE note SET ordinality = ?, content = ? WHERE id = ?",
            newData.ordinality,
            newData.content,
            id
        );
        db.commit();
        return Note(id, note.noteListId, newData.ordinality, newData.content);
    }

    void deleteNote(string username, ulong id) {
        Database db = getDb(username);
        ResultRange result = db.execute("SELECT * FROM note WHERE id = ?", id);
        if (result.empty) return;
        Note note = parseNote(result.front);
        db.begin();
        db.execute("DELETE FROM note WHERE id = ?", id);
        db.execute(
            "UPDATE note SET ordinality = ordinality - 1 WHERE ordinality > ? AND note_list_id = ?",
            note.ordinality,
            note.noteListId
        );
        db.commit();
    }

    ulong countNotes(string username) {
        return getDb(username)
            .execute("SELECT COUNT(id) FROM note")
            .oneValue!ulong();
    }
    ulong countNotes(string username, ulong noteListId) {
        return getDb(username)
            .execute("SELECT COUNT(id) FROM note WHERE note_list_id = ?", noteListId)
            .oneValue!ulong();
    }
}