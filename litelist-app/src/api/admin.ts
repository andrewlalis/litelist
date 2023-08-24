import {API_URL} from "@/api/base";

export interface AdminUserInfo {
    username: string
    email: string
    admin: boolean
    listCount: number
    noteCount: number
}

export async function getAllUsers(token: string): Promise<AdminUserInfo[]> {
    const response = await fetch(API_URL + "/admin/users", {
        headers: {"Authorization": "Bearer " + token}
    })
    if (response.ok) {
        return await response.json()
    }
    throw response
}
