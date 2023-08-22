module data.model;

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
