<script setup lang="ts">
import {ref} from "vue";

const loginModel = ref({
  username: "",
  password: ""
})

function resetLogin() {
  loginModel.value.username = ""
  loginModel.value.password = ""
}

async function doLogin() {
  try {
    const response = await fetch(
        "http://localhost:8080/login",
        {
          method: "POST",
          mode: "no-cors",
          body: JSON.stringify(loginModel.value)
        }
    )
    console.log(response.json())
  } catch (error: AxiosError) {
    console.error(error)
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