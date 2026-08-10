// Orin service worker — exists ONLY to receive Web Push reminders (see server/main.py
// _reminder_loop). No offline caching here; the app itself is a single self-contained
// HTML file and doesn't need a cache strategy from this file.
self.addEventListener("push", (event) => {
  let data = { title: "Orin", body: "" };
  try {
    data = event.data.json();
  } catch (e) {}
  event.waitUntil(
    self.registration.showNotification(data.title || "Orin", {
      body: data.body || "",
      tag: "orin-reminder",
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if ("focus" in c) return c.focus();
      }
      if (clients.openWindow) return clients.openWindow("./index.html");
    })
  );
});
