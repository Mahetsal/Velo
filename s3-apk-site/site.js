async function loadApps() {
  const grid = document.getElementById("apps-grid");
  const template = document.getElementById("app-card-template");

  try {
    const response = await fetch("./apps.json", { cache: "no-store" });
    if (!response.ok) {
      throw new Error("Failed to fetch app manifest.");
    }

    const apps = await response.json();
    grid.innerHTML = "";

    for (const app of apps) {
      const node = template.content.cloneNode(true);

      node.querySelector(".app-name").textContent = app.name;
      node.querySelector(".app-role").textContent = app.role;
      node.querySelector(".app-description").textContent = app.description;
      node.querySelector(".version").textContent = `Version: ${app.version}`;
      node.querySelector(".build-date").textContent = `Build: ${app.buildDate}`;

      const button = node.querySelector(".download-btn");
      const status = node.querySelector(".status");

      button.href = app.apkPath;
      button.textContent = "Download APK";

      if (app.apkPath && !app.apkPath.endsWith(".apk")) {
        status.textContent = "Pending";
        status.classList.add("pending");
        button.classList.add("disabled");
        button.removeAttribute("href");
        button.textContent = "APK not linked";
      } else {
        status.textContent = "Ready";
        status.classList.add("live");
      }

      grid.appendChild(node);
    }
  } catch (error) {
    grid.innerHTML =
      '<p class="error">Could not load app list. Update <code>apps.json</code> and refresh.</p>';
    console.error(error);
  }
}

loadApps();
