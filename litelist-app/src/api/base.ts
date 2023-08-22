export const API_URL = import.meta.env.VITE_API_URL

export interface StatusInfo {
    virtualMemory: number
    physicalMemory: number
}

export async function getStatus(): Promise<StatusInfo | null> {
    try {
        const response = await fetch(API_URL + "/status")
        if (response.ok) {
            return await response.json()
        }
        console.warn("Non-OK status response: ", response.status)
        return null
    } catch (error: any) {
        console.error(error)
        return null
    }
}
