import {
  CustomEditor,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

class TerminalCursorOnlyEditor extends CustomEditor {
  getSessionName: () => string | undefined = () => undefined;

  render(width: number): string[] {
    const lines = super.render(width).map((line) =>
      // Remove Pi's reverse-video software cursor.
      line.replace(/\x1b\[7m([^\x1b]*)\x1b\[0m/, "$1"),
    );

    const sessionName = this.getSessionName()?.replace(/\s+/g, " ").trim();
    if (!sessionName || lines.length === 0 || width < 5) return lines;

    const name = truncateToWidth(sessionName, width - 4, "...");
    const label = `\x1b[2m ${name} \x1b[22m`;
    const labelWidth = visibleWidth(label);
    const bottom = lines.length - 1;
    lines[bottom] =
      truncateToWidth(lines[bottom]!, width - labelWidth, "") + label;

    return lines;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      tui.setShowHardwareCursor(true);
      const editor = new TerminalCursorOnlyEditor(tui, theme, keybindings);
      editor.getSessionName = () => pi.getSessionName();
      return editor;
    });
  });
}
