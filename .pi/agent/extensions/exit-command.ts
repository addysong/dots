/**
 * Extension: exit-command
 * 
 * Adds /exit as an alias for /quit (Ctrl+D).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("exit", {
    description: "Exit pi (same as /quit or Ctrl+D)",
    handler: async (_args, ctx) => {
      ctx.shutdown();
    },
  });
}
