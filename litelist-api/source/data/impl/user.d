module data.impl.user;

import std.file;
import std.path;
import std.json;
import std.typecons;

import data.user;

immutable string USERS_DIR = "users";
immutable string DATA_FILE = "user.json";
immutable string DB_FILE = "notes.sqlite";

class FileSystemUserDataSource : UserDataSource {
    User createUser(string username, string email, string passwordHash) {
        string dirPath = buildPath(USERS_DIR, username);
        if (exists(dirPath)) throw new Exception("User already has a directory.");
        mkdirRecurse(dirPath);
        string dataPath = buildPath(dirPath, DATA_FILE);
        JSONValue userObj = JSONValue(string[string].init);
        userObj.object["email"] = JSONValue(email);
        userObj.object["passwordHash"] = JSONValue(passwordHash);
        userObj.object["admin"] = JSONValue(false);
        std.file.write(dataPath, userObj.toPrettyString());
        return User(username, email, passwordHash);
    }

    void deleteUser(string username) {
        string dirPath = buildPath(USERS_DIR, username);
        if (exists(dirPath)) rmdirRecurse(dirPath);
    }

    Nullable!User getUser(string username) {
        import std.string : strip;
        string dataPath = buildPath(USERS_DIR, username, DATA_FILE);
        if (exists(dataPath) && isFile(dataPath)) {
            JSONValue userObj = parseJSON(strip(readText(dataPath)));
            string email = userObj.object["email"].str;
            string passwordHash = userObj.object["passwordHash"].str;
            bool admin = false;
            if ("admin" !in userObj.object) {
                userObj.object["admin"] = JSONValue(false);
                std.file.write(dataPath, userObj.toPrettyString());
            } else {
                admin = userObj.object["admin"].boolean;
            }
            return nullable(User(username, email, passwordHash, admin));
        }
        return Nullable!User.init;
    }
}
