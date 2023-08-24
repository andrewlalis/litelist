<script setup lang="ts">
import PageContainer from "@/components/PageContainer.vue";
import type {Ref} from "vue";
import type {AdminUserInfo} from "@/api/admin";
import {onMounted, ref} from "vue";
import {getAllUsers} from "@/api/admin";
import {useAuthStore} from "@/stores/auth";

const authStore = useAuthStore()
const users: Ref<AdminUserInfo[]> = ref([])

onMounted(async () => {
  users.value = await getAllUsers(authStore.token)
})
</script>

<template>
  <PageContainer>
    <h1>Admin</h1>
    <p>
      This is the admin page!
    </p>
    <h3>Users</h3>
    <table>
      <thead>
        <tr>
          <th>Username</th>
          <th>Email</th>
          <th>Admin</th>
          <th>List Count</th>
          <th>Note Count</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in users" :key="user.username">
          <td v-text="user.username"/>
          <td v-text="user.email"/>
          <td v-text="user.admin"/>
          <td v-text="user.listCount"/>
          <td v-text="user.noteCount"/>
        </tr>
      </tbody>
    </table>
  </PageContainer>
</template>

<style scoped>

</style>