<script setup lang="ts">
import {ref} from "vue";
import {login, type LoginError} from "@/api/auth";
import {useAuthStore} from "@/stores/auth";
import {useRouter} from "vue-router";

const loginModel = ref({
  username: "",
  password: ""
})

const authStore = useAuthStore()
const router = useRouter()

function resetLogin() {
  loginModel.value.username = ""
  loginModel.value.password = ""
}

async function doLogin() {
  try {
    const info = await login(loginModel.value.username, loginModel.value.password)
    authStore.logIn(info.token, info.user)
    await router.push("lists")
  } catch (error: any) {
    console.error(error.message)
  }
}
</script>

<template>
<form @submit.prevent="doLogin" @reset="resetLogin">
  <h1>LiteList</h1>
  <label>
    Username:
    <input type="text" name="username" required v-model="loginModel.username"/>
  </label>
  <label>
    Password:
    <input type="password" name="password" required v-model="loginModel.password"/>
  </label>
  <button type="submit">Submit</button>
</form>
</template>

<style scoped>

</style>