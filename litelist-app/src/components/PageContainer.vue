<!--
This is a generic container to wrap around a page's content to keep it within
a mobile-friendly width.
-->
<script setup lang="ts">
</script>

<template>
  <div class="page-container">
    <slot/>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 50ch;
  margin: 0 auto;
  padding: 0.5rem;
}
</style>