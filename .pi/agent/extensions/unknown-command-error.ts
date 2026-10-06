/**
 * Extension: unknown-command-error
 * 
 * Shows an error when a non-existent slash command is invoked, instead of
 * forwarding it as a prompt to the agent.
 * 
 * Covers extension commands, skill commands, and prompt templates.
 * Use // (double slash) as an escape hatch to send a literal /-prefixed
 * prompt to the agent (e.g. //something).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

// ---- Prompt template discovery ----

function getPackagePromptDirs(baseDir: string): string[] {
  const dirs: string[] = [];
  for (const sub of ["npm", "git"]) {
    const pkgBase = join(baseDir, sub);
    try {
      if (!existsSync(pkgBase)) continue;
      for (const pkg of readdirSync(pkgBase, { withFileTypes: true })) {
        if (!pkg.isDirectory()) continue;
        const promptsDir = join(pkgBase, pkg.name, "prompts");
        if (existsSync(promptsDir)) dirs.push(promptsDir);
      }
    } catch {}
  }
  return dirs;
}

function collectTemplateNames(dirs: string[]): Set<string> {
  const names = new Set<string>();
  for (const dir of dirs) {
    try {
      if (!existsSync(dir)) continue;
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.isFile() && entry.name.endsWith(".md")) {
          names.add(entry.name.replace(/\.md$/, ""));
        }
      }
    } catch {}
  }
  return names;
}

function buildTemplateNames(agentDir: string, cwd: string): Set<string> {
  const dirs: string[] = [
    join(agentDir, "prompts"),
    join(cwd, ".pi", "prompts"),
    ...getPackagePromptDirs(agentDir),
    ...getPackagePromptDirs(join(cwd, ".pi")),
  ];
  return collectTemplateNames(dirs);
}

// ---- Skill discovery ----
// Skills are directories containing SKILL.md. The skill name is the
// directory name (unless overridden by frontmatter in SKILL.md).

function getPackageSkillDirs(baseDir: string): string[] {
  const dirs: string[] = [];
  for (const sub of ["npm", "git"]) {
    const pkgBase = join(baseDir, sub);
    try {
      if (!existsSync(pkgBase)) continue;
      for (const pkg of readdirSync(pkgBase, { withFileTypes: true })) {
        if (!pkg.isDirectory()) continue;
        const skillsDir = join(pkgBase, pkg.name, "skills");
        if (existsSync(skillsDir)) dirs.push(skillsDir);
      }
    } catch {}
  }
  return dirs;
}

function collectSkillNames(dirs: string[]): Set<string> {
  const names = new Set<string>();
  for (const dir of dirs) {
    try {
      if (!existsSync(dir)) continue;
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        const skillMd = join(dir, entry.name, "SKILL.md");
        if (existsSync(skillMd)) names.add(entry.name);
      }
    } catch {}
  }
  return names;
}

function buildSkillNames(agentDir: string, cwd: string): Set<string> {
  const dirs: string[] = [
    join(agentDir, "skills"),
    join(homedir(), ".agents", "skills"),
    join(cwd, ".pi", "skills"),
    join(cwd, ".agents", "skills"),
    ...getPackageSkillDirs(agentDir),
    ...getPackageSkillDirs(join(cwd, ".pi")),
  ];
  return collectSkillNames(dirs);
}

// ---- Cache ----

interface Cache {
  templates: Set<string>;
  skills: Set<string>;
}

export default function (pi: ExtensionAPI) {
  let cache: Cache | null = null;

  function getCache(cwd: string): Cache {
    const agentDir =
      process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
    if (!cache) {
      cache = {
        templates: buildTemplateNames(agentDir, cwd),
        skills: buildSkillNames(agentDir, cwd),
      };
    }
    return cache;
  }

  pi.on("session_start", (_event, ctx) => {
    cache = null;
    getCache(ctx.cwd);
  });

  pi.on("input", async (event, ctx) => {
    const text = event.text;

    if (!text.startsWith("/")) return { action: "continue" };

    // Escape hatch: //something goes to the agent as a literal prompt
    if (text.startsWith("//")) return { action: "continue" };

    const spaceIndex = text.indexOf(" ");
    const commandName =
      spaceIndex === -1 ? text.slice(1) : text.slice(1, spaceIndex);

    // Skill commands — validate the skill exists
    if (commandName.startsWith("skill:")) {
      const skillName = commandName.slice(6);
      const { skills } = getCache(ctx.cwd);
      if (skills.has(skillName)) return { action: "continue" };

      ctx.ui.notify(`Unknown skill: ${skillName}.`, "error");
      return { action: "handled" };
    }

    // Prompt templates — validate the template exists
    const { templates } = getCache(ctx.cwd);
    if (templates.has(commandName)) return { action: "continue" };

    // Not a known skill, template, or extension command — reject
    ctx.ui.notify(`Unknown command: /${commandName}.`, "error");
    return { action: "handled" };
  });
}
