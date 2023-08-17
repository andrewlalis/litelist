<script setup lang="ts">
import {useAuthStore} from "@/stores/auth";
import {onMounted, ref, type Ref} from "vue";
import type {NoteList} from "@/api/lists";
import {getNoteLists} from "@/api/lists";

const authStore = useAuthStore()
const noteLists: Ref<NoteList[]> = ref([])

onMounted(async () => {
  noteLists.value = await getNoteLists(authStore.token)
})
</script>

<template>
  <h1>
    Lists
  </h1>
  <p>
    Here are your lists!
  </p>
  <div v-for="list in noteLists" :key="list.id">
    <h3 v-text="list.name"></h3>
    <ul>
      <li v-for="note in list.notes" :key="note.id" v-text="note.content"></li>
    </ul>
  </div>
</template>

<style scoped>

</style>