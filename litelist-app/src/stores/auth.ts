import {defineStore} from "pinia";
import {type Ref, ref} from "vue";
import type {User} from "@/api/auth";

export const useAuthStore = defineStore("auth", () => {
    const authenticated: Ref<boolean> = ref(false)
    const user: Ref<User | null> = ref(null)
    const token: Ref<string | null> = ref(null)

    function logIn(newToken: string, newUser: User) {
        authenticated.value = true
        user.value = newUser
        token.value = newToken
    }

    function logOut() {
        authenticated.value = false
        user.value = null
        token.value = null
    }

    return {authenticated, user, token, logIn, logOut}
})

export type AuthStore = typeof useAuthStore
