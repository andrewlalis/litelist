<script setup lang="ts">
import {useAuthStore} from "@/stores/auth";

const authStore = useAuthStore()

async function doLogOut() {
  await authStore.logOut()
}
</script>

<template>
  <div class="button-container">
    <button @click="doLogOut()">
      Log Out
    </button>
  </div>
</template>

<style scoped>
.button-container {
  max-width: 50ch;
  margin: 0 auto;
}

button {
  font-size: medium;
}
</style>