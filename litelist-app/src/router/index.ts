import { createRouter, createWebHistory } from 'vue-router'
import LoginView from "@/views/LoginView.vue";
import ListsView from "@/views/ListsView.vue";
import {useAuthStore} from "@/stores/auth";
import SingleListView from "@/views/SingleListView.vue";

function checkAuth() {
  const authStore = useAuthStore()
  if (!authStore.authenticated) return "login"
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home-redirect",
      redirect: to => {
        return "/login"
      }
    },
    {
      path: "/login",
      component: LoginView
    },
    {
      path: "/lists",
      component: ListsView,
      beforeEnter: checkAuth
    },
    {
      path: "/lists/:id",
      component: SingleListView,
      beforeEnter: checkAuth
    }
  ]
})

export default router
