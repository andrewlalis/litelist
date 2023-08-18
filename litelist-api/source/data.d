module data;

import handy_httpd;
import d2sqlite3;

import std.path;
import std.file;
import std.stdio;
import std.typecons;
import std.string;
import std.json;

static UserDataSource userDataSource;

static this() {
    userDataSource = new FsSqliteDataSource();
    import slf4d;
    import d2sqlite3.library;
    infoF!"Sqlite version %s"(versionString());
}

struct User {
    string username;
    string email;
    string passwordHash;
}

struct NoteList {
    ulong id;
    string name;
    uint ordinality;
    string description;
    Note[] notes;
}

struct Note {
    ulong id;
    ulong noteListId;
    uint ordinality;
    string content;
}

interface UserDataSource {
    User createUser(string username, string email, string passwordHash);
    void deleteUser(string username);
    Nullable!User getUser(string username);
    NoteList[] getLists(string username);
    Nullable!NoteList getList(string username, ulong id);
    NoteList createNoteList(string username, string name, string description = null);
    void deleteNoteList(string username, ulong id);
    NoteList updateNoteList(string username, ulong id, NoteList newData);
    Note createNote(string username, ulong noteListId, string content);
    Note updateNote(string username, ulong id, Note newData);
    void deleteNote(string username, ulong id);
}

private immutable string USERS_DIR = "users";
private immutable string DATA_FILE = "user.json";
private immutable string DB_FILE = "notes.sqlite";

class FsSqliteDataSource : UserDataSource {
    User createUser(string username, string email, string passwordHash) {
        string dirPath = buildPath(USERS_DIR, username);
        if (exists(dirPath)) throw new Exception("User already has a directory.");
        mkdir(dirPath);
        string dataPath = buildPath(dirPath, DATA_FILE);
        JSONValue userObj = JSONValue(string[string].init);
        userObj.object["username"] = username;
        userObj.object["email"] = email;
        userObj.object["passwordHash"] = passwordHash;
        std.file.write(dataPath, userObj.toPrettyString());
        
        // Set up a default list.
        NoteList defaultList = this.createNoteList(username, "Default", "Your default list of notes.");
        this.createNote(username, defaultList.id, "Here's an example note that was added to the Default list.");
        
        return User(username, email, passwordHash);
    }

    void deleteUser(string username) {
        string dirPath = buildPath(USERS_DIR, username);
        if (exists(dirPath)) rmdirRecurse(dirPath);
    }

    Nullable!User getUser(string username) {
        string dataPath = buildPath(USERS_DIR, username, DATA_FILE);
        if (exists(dataPath) && isFile(dataPath)) {
            JSONValue userObj = parseJSON(strip(readText(dataPath)));
            return nullable(User(
                userObj.object["username"].str,
                userObj.object["email"].str,
                userObj.object["passwordHash"].str
            ));
        }
        return Nullable!User.init;
    }

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

    Nullable!NoteList getList(string username, ulong id) {
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

    NoteList createNoteList(string username, string name, string description = null) {
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
                    "UPDATE note SET ordinality = ordinality - 1 WHERE ordinality > ? AND ordinality <= ?",
                    note.ordinality,
                    newData.ordinality
                );
            } else {
                // Increment all notes between the old index and the new one.
                db.execute(
                    "UPDATE note SET ordinality = ordinality + 1 WHERE ordinality >= ? AND ordinality < ?",
                    newData.ordinality,
                    note.ordinality
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
        db.begin();
        Nullable!uint ordinality = db.execute(
            "SELECT ordinality FROM note WHERE id = ?", id
        ).oneValue!(Nullable!uint)();
        db.execute("DELETE FROM note WHERE id = ?", id);
        if (!ordinality.isNull) {
            db.execute("UPDATE note SET ordinality = ordinality - 1 WHERE ordinality > ?", ordinality.get);
        }
        db.commit();
    }

    private NoteList parseNoteList(Row row) {
        NoteList list;
        list.id = row["id"].as!ulong;
        list.name = row["name"].as!string;
        list.ordinality = row["ordinality"].as!uint;
        list.description = row["description"].as!string;
        return list;
    }

    private Note parseNote(Row row) {
        Note note;
        note.id = row["id"].as!ulong;
        note.noteListId = row["note_list_id"].as!ulong;
        note.ordinality = row["ordinality"].as!uint;
        note.content = row["content"].as!string;
        return note;
    }

    private Database getDb(string username) {
        string dbPath = buildPath(USERS_DIR, username, DB_FILE);
        if (!exists(dbPath)) initDb(dbPath);
        return Database(dbPath);
    }

    private void initDb(string path) {
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
}
