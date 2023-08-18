import {defineStore} from "pinia";
import {type Ref, ref} from "vue";
import type {User} from "@/api/auth";
import {emptyUser} from "@/api/auth";

export const useAuthStore = defineStore("auth", () => {
    const authenticated: Ref<boolean> = ref(false)
    const user: Ref<User> = ref(emptyUser())
    const token: Ref<string> = ref("")

    function logIn(newToken: string, newUser: User) {
        authenticated.value = true
        user.value = newUser
        token.value = newToken
    }

    function logOut() {
        authenticated.value = false
        user.value = emptyUser()
        token.value = ""
    }

    return {authenticated, user, token, logIn, logOut}
})

export type AuthStore = typeof useAuthStore
