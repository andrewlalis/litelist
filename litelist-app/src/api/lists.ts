import {API_URL} from "@/api/base";

export interface Note {
    id: number
    ordinality: number
    content: string
    noteListName: string
}

export interface NoteList {
    name: string
    ordinality: number
    description: string
    notes: Note[]
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