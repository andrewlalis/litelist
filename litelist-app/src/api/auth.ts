import {API_URL} from "@/api/base";

export interface User {
    username: string
    email: string
}

export interface LoginInfo {
    user: User
    token: string
}

export interface LoginError {
    message: string
}

interface LoginTokenResponse {
    token: string
}

export async function login(username: string, password: string): Promise<LoginInfo> {
    let response: Response | null = null
    try {
        response = await fetch(
            API_URL + "/login",
            {
                method: "POST",
                body: JSON.stringify({username: username, password: password})
            }
        )
    } catch (error: any) {
        throw {message: "Request failed: " + error.message}
    }
    if (response.ok) {
        const content: LoginTokenResponse = await response.json()
        const token = content.token
        const userResponse = await fetch(API_URL + "/me", {
            headers: {
                "Authorization": "Bearer " + token
            }
        })
        const user: User = await userResponse.json()
        return {token: token, user: user}
    } else if (response.status < 500) {
        throw {message: "Invalid credentials."}
    } else {
        throw {message: "Server error. Try again later."}
    }
}
