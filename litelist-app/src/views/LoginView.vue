<script setup lang="ts">
import {ref} from "vue";
import {login, type LoginError, register} from "@/api/auth";
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
  email: ""
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
    await router.push("/lists")
  } catch (error: any) {
    console.error(error.message)
  }
}

function resetRegister() {
  registerModel.value.username = ""
  registerModel.value.email = ""
  registerModel.value.password = ""
}

async function doRegister() {
  try {
    await register(registerModel.value.username, registerModel.value.email, registerModel.value.password)
    const info = await login(registerModel.value.username, registerModel.value.password)
    await authStore.logIn(info.token, info.user)
    await router.push("/lists")
  } catch (error: any) {
    console.error(error)
  }
}
</script>

<template>
  <PageContainer>
    <h1>LiteList</h1>

    <div class="login-container">
      <!-- Login form that's shown if the user is logging in (default) -->
      <form v-if="!registering" @submit.prevent="doLogin" @reset="resetLogin">
        <div class="form-row">
          <label for="login-username-input">Username</label>
          <input
              id="login-username-input"
              type="text"
              name="username"
              required
              v-model="loginModel.username"
              minlength="3"
          />
        </div>
        <div class="form-row">
          <label for="login-password-input">Password</label>
          <input
              id="login-password-input"
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

      <!-- Registration form that's shown if the user is registering (default) -->
      <form v-if="registering" @submit.prevent="doRegister" @reset="resetRegister">
        <div class="form-row">
          <label for="register-username-input">Username</label>
          <input
            id="register-username-input"
            type="text"
            name="username"
            required
            minlength="3"
            maxlength="12"
            v-model="registerModel.username"
          />
        </div>
        <div class="form-row">
          <label for="register-email-input">Email</label>
          <input
            id="register-email-input"
            type="email"
            name="email"
            required
            v-model="registerModel.email"
          />
        </div>
        <div class="form-row">
          <label for="register-password-input">Password</label>
          <input
              id="register-password-input"
              type="password"
              name="password"
              required
              v-model="registerModel.password"
              minlength="8"
          />
        </div>
        <div class="form-row">
          <button type="submit">Register</button>
        </div>
      </form>

      <button v-if="!registering" @click="registering = true">Create an Account</button>
      <button v-if="registering" @click="registering = false">Log in with an existing account</button>
    </div>
  </PageContainer>
</template>

<style scoped>
h1 {
  text-align: center;
}

.login-container {
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