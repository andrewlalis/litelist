<script setup lang="ts">
import {useAuthStore} from "@/stores/auth";

const authStore = useAuthStore()

async function doLogOut() {
  await authStore.logOut()
}
</script>

<template>
  <button @click="doLogOut()">
    Log Out
  </button>
</template>

<style scoped>
button {
  font-size: medium;
}
</style>