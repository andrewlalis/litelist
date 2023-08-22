import {API_URL} from "@/api/base";

export interface User {
    username: string
    email: string
}

export function emptyUser(): User {
    return {username: "", email: ""}
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
        const user = await getMyUser(token)
        return {token: token, user: user}
    } else if (response.status < 500) {
        throw {message: "Invalid credentials."}
    } else {
        throw {message: "Server error. Try again later."}
    }
}

export async function register(username: string, email: string, password: string): Promise<void> {
    const response = await fetch(API_URL + "/register", {
        method: "POST",
        body: JSON.stringify({username: username, email: email, password: password})
    })
    if (response.ok) return;
    throw response
}

export async function getMyUser(token: string): Promise<User> {
    const userResponse = await fetch(API_URL + "/me", {
        headers: {
            "Authorization": "Bearer " + token
        }
    })
    if (userResponse.ok) return await userResponse.json()
    throw userResponse
}

export async function renewToken(token: string): Promise<string> {
    const response = await fetch(API_URL + "/renew-token", {
        headers: {"Authorization": "Bearer " + token}
    })
    if (response.ok) {
        const content: LoginTokenResponse = await response.json()
        return content.token
    }
    throw response
}
