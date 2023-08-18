import {API_URL} from "@/api/base";

export interface Note {
    id: number
    ordinality: number
    content: string
    noteListId: number
}

export interface NoteList {
    id: number
    name: string
    ordinality: number
    description: string
    notes: Note[]
}

export async function createNoteList(token: string, name: string, description: string | null): Promise<NoteList> {
    const response = await fetch(API_URL + "/lists", {
        method: "POST",
        headers: {"Authorization": "Bearer " + token},
        body: JSON.stringify({name: name, description: description})
    })
    if (response.ok) {
        return await response.json()
    } else {
        throw response
    }
}

export async function getNoteLists(token: string): Promise<NoteList[]> {
    const response = await fetch(API_URL + "/lists", {
        headers: {"Authorization": "Bearer " + token}
    })
    if (response.ok) {
        return await response.json()
    } else {
        console.error(response)
        return []
    }
}

export async function getNoteList(token: string, id: number): Promise<NoteList | null> {
    const response = await fetch(API_URL + "/lists/" + id, {
        headers: {"Authorization": "Bearer " + token}
    })
    if (response.ok) {
        return await response.json()
    } else {
        return null
    }
}

export async function deleteNoteList(token: string, id: number): Promise<void> {
    await fetch(API_URL + "/lists/" + id, {
        method: "DELETE",
        headers: {"Authorization": "Bearer " + token}
    })
}

export async function createNote(token: string, listId: number, content: string): Promise<Note> {
    const response = await fetch(API_URL + "/lists/" + listId + "/notes", {
        method: "POST",
        headers: {"Authorization": "Bearer " + token},
        body: JSON.stringify({content: content})
    })
    if (response.ok) {
        return await response.json()
    } else {
        throw response
    }
}

export async function deleteNote(token: string, listId: number, id: number): Promise<void> {
    await fetch(API_URL + "/lists/" + listId + "/notes/" + id, {
        method: "DELETE",
        headers: {"Authorization": "Bearer " + token}
    })
}
