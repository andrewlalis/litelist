<script setup lang="ts">
import {useAuthStore} from "@/stores/auth";
import {nextTick, onMounted, ref, type Ref} from "vue";
import type {NoteList} from "@/api/lists";
import {createNoteList, getNoteLists} from "@/api/lists";
import {useRouter} from "vue-router";
import {stringToColor} from "@/util";
import LogOutButton from "@/components/LogOutButton.vue";

const authStore = useAuthStore()
const router = useRouter()
const noteLists: Ref<NoteList[]> = ref([])

const creatingNewList: Ref<boolean> = ref(false)
const newListModel = ref({
  name: "",
  description: ""
})

onMounted(async () => {
  noteLists.value = await getNoteLists(authStore.token)
})

function toggleCreatingNewList() {
  if (!creatingNewList.value) {
    newListModel.value.name = ""
    newListModel.value.description = ""
  }
  creatingNewList.value = !creatingNewList.value
  if (creatingNewList.value) {
    nextTick(() => {
      const nameField: HTMLElement | null = document.getElementById("list-name")
      if (nameField) nameField.focus()
    })
  }
}

async function goToList(id: number) {
  await router.push("/lists/" + id)
}

async function createList() {
  await createNoteList(
      authStore.token,
      newListModel.value.name,
      newListModel.value.description
  )
  noteLists.value = await getNoteLists(authStore.token)
}
</script>

<template>
  <header>
    <h1>Lists</h1>
    <div>
      <button @click="toggleCreatingNewList()">
        Create New List
      </button>
    </div>
  </header>

  <form v-if="creatingNewList" class="new-list-form" @submit.prevent="createList()">
    <div class="form-row">
      <label for="list-name">Name</label>
      <input type="text" id="list-name" required minlength="3" v-model="newListModel.name"/>
    </div>
    <div class="form-row">
      <label for="list-description">Description</label>
      <input type="text" id="list-description" v-model="newListModel.description"/>
    </div>
    <div class="form-row">
      <button type="submit">Create List</button>
    </div>
  </form>

  <div
      class="note-list-item"
      v-for="list in noteLists"
      :key="list.id"
      @click="goToList(list.id)"
      :style="{'background-color': stringToColor(list.name, 100, 90)}"
  >
    <h3 v-text="list.name"></h3>
    <p v-text="list.description"></p>
  </div>

  <div>
    <LogOutButton/>
  </div>
</template>

<style scoped>
h1 {
  text-align: center;
}
header {
  max-width: 50ch;
  margin: 0 auto;
}

.note-list-item {
  display: block;
  max-width: 50ch;
  margin: 1rem auto;
  padding: 1rem;
  border-radius: 1rem;
  border: 2px solid black;
  position: relative;
}

.note-list-item:hover {
  cursor: pointer;
}

.note-list-item h3 {
  margin: 0;
}

.note-list-item p {
  margin: 0.5rem 0;
  font-style: italic;
  font-size: small;
}

.new-list-form {
  max-width: 50ch;
  margin: 0 auto;
}

.form-row {
  margin: 1rem 0;
}

.form-row label {
  display: block;
}
</style>