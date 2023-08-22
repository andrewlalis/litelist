module data.user;

public import data.model : User;

import std.typecons : Nullable;

interface UserDataSource {
    User createUser(string username, string email, string passwordHash);
    void deleteUser(string username);
    Nullable!User getUser(string username);
}

static UserDataSource userDataSource;
static this() {
    import data.impl.user;
    userDataSource = new FileSystemUserDataSource();
}
