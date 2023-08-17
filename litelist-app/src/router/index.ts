import { createRouter, createWebHistory } from 'vue-router'
import LoginView from "@/views/LoginView.vue";
import ListsView from "@/views/ListsView.vue";
import {useAuthStore} from "@/stores/auth";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home-redirect",
      redirect: to => {
        return "login"
      }
    },
    {
      path: "/login",
      name: "login",
      component: LoginView
    },
    {
      path: "/lists",
      name: "lists",
      component: ListsView,
      beforeEnter: (to, from) => {
        const authStore = useAuthStore()
        if (!authStore.authenticated) return "login"
      }
    }
  ]
})

export default router
