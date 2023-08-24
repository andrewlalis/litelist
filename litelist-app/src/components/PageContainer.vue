<!--
This is a generic container to wrap around a page's content to keep it within
a mobile-friendly width.
-->
<script setup lang="ts">
import type {Ref} from "vue";
import {onMounted, onUnmounted, ref} from "vue";
import type {StatusInfo} from "@/api/base";
import {getStatus} from "@/api/base";
import {humanFileSize} from "@/util";
import {useAuthStore} from "@/stores/auth";

const statusInfo: Ref<StatusInfo | null> = ref(null)
const statusRefreshInterval: Ref<number | null> = ref(null);
const authStore = useAuthStore()

onMounted(async () => {
  statusInfo.value = await getStatus()
  statusRefreshInterval.value = setInterval(async () => {
    statusInfo.value = await getStatus()
  }, 5000)
})

onUnmounted(() => {
  if (statusRefreshInterval.value) {
    clearInterval(statusRefreshInterval.value)
  }
})
</script>

<template>
  <div class="page-container">
    <slot/>
    <!-- Each contained page also gets a nice little footer! -->
    <footer style="text-align: center; margin-top: 2rem;">
      <p style="font-size: smaller">
        LiteList created with ❤️ by
        <a href="https://andrewlalis.com" target="_blank">Andrew Lalis</a>
        using <a href="https://vuejs.org/" target="_blank">🌿 Vue 3</a> and
        <a href="https://github.com/andrewlalis/handy-httpd" target="_blank">🌎 Handy-Httpd</a>.
      </p>
      <p v-if="statusInfo" style="font-size: smaller; font-family: monospace;">
        Memory used: <span v-text="humanFileSize(statusInfo.physicalMemory, true, 1)"></span>
      </p>
      <p v-if="authStore.authenticated && authStore.user.admin" style="font-size: smaller">
        <RouterLink to="/admin">Admin Page</RouterLink>
      </p>
    </footer>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 50ch;
  margin: 0 auto;
  padding: 0.5rem;
}
</style>