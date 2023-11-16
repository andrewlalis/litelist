<!--
A "printable" list view that, when opened, immediately triggers the browser's
print dialog on the page. Users will navigate to this view via "/lists/123/print".
-->
<script setup lang="ts">
import type {Ref} from "vue";
import type {NoteList} from "@/api/lists";
import {onMounted, ref} from "vue";
import {useRoute, useRouter} from "vue-router";
import {useAuthStore} from "@/stores/auth";
import {getNoteList} from "@/api/lists";

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const list: Ref<NoteList | null> = ref(null)

onMounted(async () => {
  let listId: number | null = null
  if (!Array.isArray(route.params.id)) listId = parseInt(route.params.id)
  if (!listId) {
    await router.push("/lists")
    return
  }

  list.value = await getNoteList(authStore.token, listId)
  if (list.value === null) {
    await router.push("/lists")
    return
  }

  setTimeout(window.print, 100)
})
</script>

<template>
  <div v-if="list">
    <header>
      <h1 v-text="list.name"></h1>
      <p v-text="list.description"></p>
    </header>
    <main>
      <div class="note-item" v-for="note in list.notes" :key="note.id">
        <input type="checkbox" :id="'note-' + note.id"/>
        <label :for="'note-' + note.id" v-text="note.content"></label>
      </div>
    </main>
  </div>
</template>

<style scoped>
.note-item {
  margin: 1rem 0;
}
</style>