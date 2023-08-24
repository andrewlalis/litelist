module data.impl.list;

import data.list;
import data.impl.sqlite3_helpers;
import d2sqlite3;
import handy_httpd;

import std.typecons;

class SqliteNoteListDataSource : NoteListDataSource {
    NoteList[] getLists(string username) {
        Database db = getDb(username);
        ResultRange results = db.execute("SELECT * FROM note_list ORDER BY ordinality ASC");
        NoteList[] lists;
        foreach (Row row; results) {
            lists ~= parseNoteList(row);
        }
        // Now eager-fetch notes for each list.
        Statement stmt = db.prepare("SELECT * FROM note WHERE note_list_id = ? ORDER BY ordinality ASC");
        foreach (ref list; lists) {
            stmt.bind(1, list.id);
            ResultRange noteResult = stmt.execute();
            foreach (row; noteResult) list.notes ~= parseNote(row);
            stmt.reset();
        }
        return lists;
    }

    Nullable!NoteList getList(string username, ulong id){
        Database db = getDb(username);
        ResultRange results = db.execute("SELECT * FROM note_list WHERE id = ?", id);
        if (results.empty()) return Nullable!NoteList.init;
        NoteList list = parseNoteList(results.front());
        ResultRange noteResults = db.execute("SELECT * FROM note WHERE note_list_id = ? ORDER BY ordinality ASC", id);
        foreach (Row row; noteResults) {
            list.notes ~= parseNote(row);
        }
        return nullable(list);
    }

    NoteList createNoteList(string username, string name, string description = null){
        Database db = getDb(username);
        Statement existsStatement = db.prepare("SELECT COUNT(name) FROM note_list WHERE name = ?");
        existsStatement.bind(1, name);
        ResultRange existsResult = existsStatement.execute();
        if (existsResult.oneValue!int() > 0) {
            throw new HttpStatusException(HttpStatus.BAD_REQUEST, "List already exists.");
        }
        
        Nullable!uint ordResult = db.execute("SELECT MAX(ordinality) + 1 FROM note_list").oneValue!(Nullable!uint);
        uint ordinality = 0;
        if (!ordResult.isNull) ordinality = ordResult.get();
        Statement stmt = db.prepare("INSERT INTO note_list (name, ordinality, description) VALUES (?, ?, ?)");
        stmt.bind(1, name);
        stmt.bind(2, ordinality);
        stmt.bind(3, description);
        stmt.execute();
        return NoteList(db.lastInsertRowid(), name, ordinality, description, []);
    }

    void deleteNoteList(string username, ulong id) {
        Database db = getDb(username);
        db.begin();
        db.execute("DELETE FROM note WHERE note_list_id = ?", id);
        Nullable!uint ordinality = db.execute(
            "SELECT ordinality FROM note_list WHERE id = ?", id
        ).oneValue!(Nullable!uint)();
        db.execute("DELETE FROM note_list WHERE id = ?", id);
        if (!ordinality.isNull) {
            db.execute("UPDATE note_list SET ordinality = ordinality - 1 WHERE ordinality > ?", ordinality.get);
        }
        db.commit();
    }

    NoteList updateNoteList(string username, ulong id, NoteList newData) {
        Database db = getDb(username);
        ResultRange result = db.execute("SELECT * FROM note_list WHERE id = ?", id);
        if (result.empty()) throw new HttpStatusException(HttpStatus.NOT_FOUND);
        NoteList list = parseNoteList(result.front());
        db.begin();
        if (list.ordinality != newData.ordinality) {
            if (newData.ordinality > list.ordinality) {
                // Decrement all lists between the old index and the new one.
                db.execute(
                    "UPDATE note_list SET ordinality = ordinality - 1 WHERE ordinality > ? AND ordinality <= ?",
                    list.ordinality,
                    newData.ordinality
                );
            } else {
                // Increment all lists between the old index and the new one.
                db.execute(
                    "UPDATE note_list SET ordinality = ordinality + 1 WHERE ordinality >= ? AND ordinality < ?",
                    newData.ordinality,
                    list.ordinality
                );
            }
        }
        db.execute(
            "UPDATE note_list SET name = ?, description = ?, ordinality = ? WHERE id = ?",
            newData.name, newData.description, newData.ordinality, id
        );
        db.commit();
        return NoteList(id, newData.name, newData.ordinality, newData.description, []);
    }

    ulong countLists(string username) {
        Database db = getDb(username);
        return db.execute("SELECT COUNT(id) FROM note_list").oneValue!ulong();
    }
}