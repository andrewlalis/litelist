<script setup lang="ts">
import type {NoteList} from "@/api/lists";
import {nextTick, onMounted, ref, type Ref} from "vue";
import {useAuthStore} from "@/stores/auth";
import {createNote, deleteAllNotes, deleteNote, deleteNoteList, getNoteList} from "@/api/lists";
import {useRoute, useRouter} from "vue-router";
import PageContainer from "@/components/PageContainer.vue";
import LogOutButton from "@/components/LogOutButton.vue";

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const list: Ref<NoteList | null> = ref(null)

const creatingNote: Ref<boolean> = ref(false)
const newNoteText: Ref<string> = ref("")

onMounted(async () => {
  let listId: number | null = null;
  if (!Array.isArray(route.params.id)) listId = parseInt(route.params.id)
  // If no valid list id could be found, go back.
  if (!listId) {
    await router.push("/lists")
    return
  }
  list.value = await getNoteList(authStore.token, listId)
  // If no such list could be found, go back to the page showing all lists.
  if (list.value === null) {
    await router.push("/lists")
  }
})

async function deleteNoteAndRefresh(id: number) {
  if (!list.value) return
  await deleteNote(authStore.token, list.value.id, id)
  list.value = await getNoteList(authStore.token, list.value.id)
}

async function deleteList(id: number) {
  const dialog = document.getElementById("list-delete-dialog") as HTMLDialogElement
  dialog.showModal()
  const confirmButton = document.getElementById("delete-confirm-button") as HTMLButtonElement
  confirmButton.onclick = async () => {
    dialog.close()
    await deleteNoteList(authStore.token, id)
    await router.push("/lists")
  }
  const cancelButton = document.getElementById("delete-cancel-button") as HTMLButtonElement
  cancelButton.onclick = async () => {
    dialog.close()
  }
}

function toggleCreatingNewNote() {
  if (!creatingNote.value) {
    newNoteText.value = ""
  }
  creatingNote.value = !creatingNote.value
  if (creatingNote.value) {
    nextTick(() => {
      const noteInput = document.getElementById("note-content")
      if (noteInput) noteInput.focus()
    })
  }
}

async function clearList() {
  if (!list.value) return
  const l: NoteList = list.value
  const dialog = document.getElementById("list-clear-notes-dialog") as HTMLDialogElement
  dialog.showModal()
  const confirmButton = document.getElementById("clear-notes-confirm-button") as HTMLButtonElement
  confirmButton.onclick = async () => {
    dialog.close()
    await deleteAllNotes(authStore.token, l.id)
    l.notes = []
  }
  const cancelButton = document.getElementById("clear-notes-cancel-button") as HTMLButtonElement
  cancelButton.onclick = async () => {
    dialog.close()
  }
}

async function createNoteAndRefresh() {
  if (!list.value) return
  await createNote(authStore.token, list.value.id, newNoteText.value)
  creatingNote.value = false
  newNoteText.value = ""
  list.value = await getNoteList(authStore.token, list.value.id)
}
</script>

<template>
  <PageContainer v-if="list">
    <header>
      <h1 v-text="list.name"></h1>
      <p><em v-text="list.description"></em></p>
      <div class="buttons-list">
        <button @click="toggleCreatingNewNote()">Add Note</button>
        <button @click="clearList()" v-if="list.notes.length > 0">Clear Notes</button>
        <button @click="deleteList(list.id)">Delete this List</button>
        <button @click="router.push('/lists')">All Lists</button>
        <LogOutButton/>
      </div>
    </header>

    <form v-if="creatingNote" @submit.prevent="createNoteAndRefresh()">
      <div class="form-row">
        <label for="note-content">Text</label>
        <input type="text" id="note-content" required minlength="1" v-model="newNoteText"/>
      </div>
      <div class="form-row">
        <button type="submit">Add</button>
        <button @click="toggleCreatingNewNote()">Cancel</button>
      </div>
    </form>

    <div class="note-item" v-for="note in list.notes" :key="note.id">
      <p class="note-item-text" v-text="note.content"></p>
      <img
          class="trash-button"
          alt="Delete button"
          src="@/assets/trash-emoji.svg"
          @click="deleteNoteAndRefresh(note.id)"
      />
    </div>

    <p v-if="list.notes.length === 0">
      <em>There are no notes in this list.</em> <button @click="toggleCreatingNewNote()">Add one!</button>
    </p>

    <RouterLink :to="'/lists/' + list.id + '/print'" target="_blank">Print this list</RouterLink>

    <dialog id="list-delete-dialog">
      <form method="dialog">
        <p>
          Are you sure you want to delete this list? All notes in it will be deleted.
        </p>
        <div>
          <button id="delete-cancel-button" value="cancel" formmethod="dialog">Cancel</button>
          <button id="delete-confirm-button" value="default">Confirm</button>
        </div>
      </form>
    </dialog>

    <dialog id="list-clear-notes-dialog">
      <form method="dialog">
        <p>
          Are you sure you want to clear <strong>all</strong> notes from this list?
        </p>
        <div>
          <button id="clear-notes-cancel-button" value="cancel" formmethod="dialog">Cancel</button>
          <button id="clear-notes-confirm-button" value="default">Confirm</button>
        </div>
      </form>
    </dialog>
  </PageContainer>
</template>

<style scoped>
h1 {
  text-align: center;
}

.buttons-list button {
  margin-right: 1rem;
  margin-top: 0.25rem;
  margin-bottom: 0.25rem;
  font-size: medium;
}

.note-item {
  margin: 1rem 0;
  position: relative;
  background-color: #fff2bd;
  color: #212121;
  font-size: large;
  padding: 0.5rem;
  min-height: 40px;
  box-shadow: 2px 2px 4px 1px black;
}

.note-item-text {
  width: 90%;
  margin: 0;
}

.trash-button {
  width: 24px;
  position: absolute;
  top: 5px;
  right: 5px;
}

.trash-button:hover {
  cursor: pointer;
  background-color: lightgray;
}

.form-row {
  margin: 1rem 0;
}

.form-row label {
  display: block;
}

.form-row button {
  margin-right: 1rem;
}

.form-row input {
  font-size: medium;
  padding: 0.25rem;
  box-sizing: border-box;
}

@media(max-width: 480px) {
  .form-row input {
    width: 100%;
  }
}
</style>