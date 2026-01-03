import { check } from "@tauri-apps/plugin-updater";
import { ask } from "@tauri-apps/plugin-dialog";
import { relaunch } from "@tauri-apps/plugin-process";
import { toast } from "sonner";

export async function checkForUpdates() {
  const update = await check();
  if (update) {
    if (
      !(await ask(
        `A new version is available: ${update.version}. Do you want to update?`
      ))
    )
      return;

    let promise = update.downloadAndInstall((event) => {
      switch (event.event) {
        case "Started":
          console.log("Started download");
          break;
        case "Progress":
          break;
        case "Finished":
          console.log("Download finished");
          break;
      }
    });

    promise.then(async () => {
      await relaunch();
    });

    toast.promise(promise, {
      loading: "Updating...",
      success: "Update downloaded! Restarting app...",
      error: (e) => `Failed to download update: ${e}`,
    });
  }
}
