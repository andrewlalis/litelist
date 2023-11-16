import {defineStore} from "pinia";
import {type Ref, ref} from "vue";
import type {User} from "@/api/auth";
import {emptyUser, getMyUser, renewToken} from "@/api/auth";
import {getSecondsTilExpire} from "@/util";
import {useRouter} from "vue-router";

const LOCAL_STORAGE_KEY = "access_token"

export const useAuthStore = defineStore("auth", () => {
    const authenticated: Ref<boolean> = ref(false)
    const user: Ref<User> = ref(emptyUser())
    const token: Ref<string> = ref("")
    const tokenRefreshInterval: Ref<number> = ref(0)

    const router = useRouter()

    async function logIn(newToken: string, newUser: User) {
        authenticated.value = true
        user.value = newUser
        token.value = newToken
        localStorage.setItem(LOCAL_STORAGE_KEY, token.value)
        tokenRefreshInterval.value = setInterval(tryRefreshToken, 60000)
        // await router.push("/lists")
    }

    async function logOut() {
        authenticated.value = false
        user.value = emptyUser()
        token.value = ""
        if (tokenRefreshInterval.value) {
            clearInterval(tokenRefreshInterval.value)
        }
        localStorage.removeItem(LOCAL_STORAGE_KEY)
        await router.push("/login")
    }

    /**
     * Periodically called to renew the access token, if it's close to expiring.
     */
    async function tryRefreshToken() {
        if (authenticated.value && getSecondsTilExpire(token.value) < 100) {
            try {
                const newToken = await renewToken(token.value)
                token.value = newToken
                localStorage.setItem(LOCAL_STORAGE_KEY, newToken)
            } catch (e: any) {
                console.warn("Failed to renew the access token.", e)
                await logOut()
            }
        }
    }

    /**
     * Tries to log in using an access token stored in the local storage.
     */
    async function tryLogInFromStoredToken(): Promise<void> {
        if (authenticated.value) return
        const storedToken: string | null = localStorage.getItem(LOCAL_STORAGE_KEY)
        if (storedToken && getSecondsTilExpire(storedToken) > 60) {
            try {
                const storedUser = await getMyUser(storedToken)
                console.log("Logging in using stored token for user: " + storedUser.username)
                await logIn(storedToken, storedUser)
            } catch (e: any) {
                console.warn("Failed to log in using stored token.", e)
            }
        }
    }

    return {
        authenticated, user, token,
        logIn, logOut,
        tryLogInFromStoredToken
    }
})
