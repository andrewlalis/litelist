<script setup lang="ts">
import {ref} from "vue";
import {login, type LoginError} from "@/api/auth";
import {useAuthStore} from "@/stores/auth";
import {useRouter} from "vue-router";
import PageContainer from "@/components/PageContainer.vue";

const loginModel = ref({
  username: "",
  password: ""
})

const registerModel = ref({
  username: "",
  password: "",
  email: "",
  code: ""
})
const registering = ref(false)

const authStore = useAuthStore()
const router = useRouter()

function resetLogin() {
  loginModel.value.username = ""
  loginModel.value.password = ""
}

async function doLogin() {
  try {
    const info = await login(loginModel.value.username, loginModel.value.password)
    await authStore.logIn(info.token, info.user)
  } catch (error: any) {
    console.error(error.message)
  }
}
</script>

<template>
  <PageContainer>
    <h1>LiteList</h1>
    <form v-if="!registering" @submit.prevent="doLogin" @reset="resetLogin">
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
        <button type="button" @click="registering = true">Create an Account</button>
      </div>
    </form>
  </PageContainer>
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
  width: 30ch;
  padding: 0.25rem;
  font-size: large;
  box-sizing: border-box;
}

.form-row button {
  margin-right: 0.5rem;
}

@media (max-width: 480px) {
  .form-row input {
    width: 100%;
  }
}

</style>