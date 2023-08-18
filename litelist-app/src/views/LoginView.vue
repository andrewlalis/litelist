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
  <h1>LiteList</h1>
  <form @submit.prevent="doLogin" @reset="resetLogin">
    <div class="form-row">
      <label for="username-input">Username</label>
      <input
          id="username-input"
          type="text"
          name="username"
          required
          v-model="loginModel.username"
          minlength="3"
      />
    </div>
    <div class="form-row">
      <label for="password-input">Password</label>
      <input
          id="password-input"
          type="password"
          name="password"
          required
          v-model="loginModel.password"
          minlength="8"
      />
    </div>
    <div class="form-row">
      <button type="submit">Login</button>
    </div>
  </form>
</template>

<style scoped>
h1 {
  text-align: center;
}

form {
  max-width: 50ch;
  margin: 0 auto;
  background-color: #efefef;
  padding: 1rem;
  border: 3px solid black;
  border-radius: 1em;
}

.form-row {
  margin: 1rem 0;
}

.form-row label {
  display: block;
}

.form-row input {
  width: 75%;
  padding: 0.5rem;
  font-size: large;
}

.form-row button {
  font-size: medium;
}

</style>