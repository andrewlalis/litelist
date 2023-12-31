import {createRouter, createWebHistory} from 'vue-router'
import LoginView from "@/views/LoginView.vue";
import ListsView from "@/views/ListsView.vue";
import {useAuthStore} from "@/stores/auth";
import SingleListView from "@/views/SingleListView.vue";
import AdminView from "@/views/AdminView.vue";
import PrintableListView from "@/views/PrintableListView.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      redirect: to => {
        return "/login"
      }
    },
    {
      path: "/login",
      component: LoginView,
      beforeEnter: () => {
        // Check if the user is already logged in, and if so, go straight to /lists.
        const authStore = useAuthStore()
        if (authStore.authenticated) {
          return "/lists"
        }
      }
    },
    {
      path: "/lists",
      component: ListsView
    },
    {
      path: "/lists/:id",
      component: SingleListView
    },
    {
      path: "/lists/:id/print",
      component: PrintableListView
    },
    {
      path: "/admin",
      component: AdminView
    }
  ]
})

const publicRoutes = [
    "/",
    "/login"
]

const adminRoutes = [
    "/admin"
]

router.beforeEach(async (to, from) => {
  const authStore = useAuthStore()
  await authStore.tryLogInFromStoredToken()
  if (!publicRoutes.includes(to.path) && !authStore.authenticated) {
    return "/login" // Redirect to login page if user is trying to go to an authenticated page.
  }
  if (adminRoutes.includes(to.path) && !authStore.user.admin) {
    return "/lists" // Redirect to /lists if a non-admin user tries to access an admin page.
  }
})

export default router
