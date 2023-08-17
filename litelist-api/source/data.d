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
    NoteList createNoteList(string username, string name, string description = null);
    void deleteNoteList(string username, ulong id);
    Note createNote(string username, ulong noteListId, string content);
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

    NoteList createNoteList(string username, string name, string description = null) {
        Database db = getDb(username);
        
        Statement existsStatement = db.prepare("SELECT COUNT(name) FROM note_list WHERE name = ?");
        existsStatement.bind(1, name);
        ResultRange existsResult = existsStatement.execute();
        if (existsResult.oneValue!int() > 0) throw new HttpStatusException(HttpStatus.BAD_REQUEST, "List already exists.");
        
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
        Statement stmt1 = db.prepare("DELETE FROM note WHERE note_list_id = ?");
        stmt1.bind(1, id);
        stmt1.execute();
        Statement stmt2 = db.prepare("DELETE FROM note_list WHERE id = ?");
        stmt2.bind(1, id);
        stmt2.execute();
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

    void deleteNote(string username, ulong id) {
        Database db = getDb(username);
        Statement stmt = db.prepare("DELETE FROM note WHERE id = ?");
        stmt.bind(1, id);
        stmt.execute();
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
