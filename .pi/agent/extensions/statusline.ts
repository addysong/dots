import { Buffer } from "node:buffer";
import { basename, resolve } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const ansi = {
  blue: (text: string) => `\x1b[34m${text}\x1b[39m`,
  red: (text: string) => `\x1b[31m${text}\x1b[39m`,
  magenta: (text: string) => `\x1b[35m${text}\x1b[39m`,
  cyan: (text: string) => `\x1b[36m${text}\x1b[39m`,
  yellow: (text: string) => `\x1b[33m${text}\x1b[39m`,
  dim: (text: string) => `\x1b[2m${text}\x1b[22m`,
};

function formatTokens(count: number): string {
  if (count < 1_000) return count.toString();
  if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function projectName(cwd: string): string {
  const resolvedCwd = resolve(cwd);
  return basename(resolvedCwd) || resolvedCwd;
}

function sanitizeStatusText(text: string): string {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

type CodexUsageWindow = {
  usedPercent: number;
  windowMinutes?: number;
  resetsAtMs: number;
};

function finiteNumber(value: unknown): number | undefined {
  if (typeof value !== "number" && typeof value !== "string") return undefined;
  if (typeof value === "string" && value.trim() === "") return undefined;
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function parseCodexUsageWindow(value: unknown): CodexUsageWindow | undefined {
  if (!value || typeof value !== "object") return undefined;
  const record = value as Record<string, unknown>;
  const usedPercent = finiteNumber(record.used_percent);
  const resetAt = finiteNumber(record.reset_at);
  if (usedPercent === undefined || resetAt === undefined) return undefined;

  const windowMinutes =
    finiteNumber(record.window_minutes) ??
    (() => {
      const windowSeconds = finiteNumber(record.limit_window_seconds);
      return windowSeconds === undefined ? undefined : windowSeconds / 60;
    })();
  return {
    usedPercent,
    windowMinutes,
    resetsAtMs: resetAt >= 1_000_000_000_000 ? resetAt : resetAt * 1_000,
  };
}

function parseCodexRateLimitEvent(data: unknown): CodexUsageWindow[] {
  if (!data || typeof data !== "object") return [];
  const event = data as Record<string, unknown>;
  if (event.type !== "codex.rate_limits") return [];

  const rateLimits = event.rate_limits;
  if (!rateLimits || typeof rateLimits !== "object") return [];
  const limits = rateLimits as Record<string, unknown>;
  return [
    parseCodexUsageWindow(limits.primary),
    parseCodexUsageWindow(limits.secondary),
  ].filter((window): window is CodexUsageWindow => window !== undefined);
}

function parseCodexUsageResponse(data: unknown): CodexUsageWindow[] {
  if (!data || typeof data !== "object") return [];
  const rateLimit = (data as Record<string, unknown>).rate_limit;
  if (!rateLimit || typeof rateLimit !== "object") return [];
  const limit = rateLimit as Record<string, unknown>;

  return [
    parseCodexUsageWindow(limit.primary_window),
    parseCodexUsageWindow(limit.secondary_window),
  ].filter((window): window is CodexUsageWindow => window !== undefined);
}

function extractCodexAccountId(token: string): string | undefined {
  try {
    const payload = token.split(".")[1];
    if (!payload) return undefined;
    const claims = JSON.parse(
      Buffer.from(payload, "base64url").toString("utf8"),
    ) as Record<string, unknown>;
    const auth = claims["https://api.openai.com/auth"];
    if (!auth || typeof auth !== "object") return undefined;
    const accountId = (auth as Record<string, unknown>).chatgpt_account_id;
    return typeof accountId === "string" && accountId.length > 0
      ? accountId
      : undefined;
  } catch {
    return undefined;
  }
}

async function fetchCodexUsage(
  ctx: ExtensionContext,
): Promise<CodexUsageWindow[]> {
  const model = ctx.model;
  if (
    !model ||
    model.provider !== "openai-codex" ||
    !ctx.modelRegistry.isUsingOAuth(model)
  ) {
    return [];
  }

  try {
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok || !auth.apiKey) return [];
    const accountId = extractCodexAccountId(auth.apiKey);
    if (!accountId) return [];

    const headers = new Headers();
    for (const [name, value] of Object.entries(auth.headers ?? {})) {
      if (value !== null) headers.set(name, value);
    }
    headers.set("authorization", `Bearer ${auth.apiKey}`);
    headers.set("chatgpt-account-id", accountId);

    const baseUrl = (
      auth.baseUrl ??
      model.baseUrl ??
      "https://chatgpt.com/backend-api"
    ).replace(/\/+$/, "");
    const usageUrl = baseUrl.endsWith("/backend-api")
      ? `${baseUrl}/wham/usage`
      : `${baseUrl}/api/codex/usage`;
    const response = await fetch(usageUrl, {
      headers,
      signal: AbortSignal.timeout(5_000),
    });
    if (!response.ok) return [];
    return parseCodexUsageResponse(await response.json());
  } catch {
    return [];
  }
}

function parseCodexRateLimitHeaders(
  headers: Record<string, string>,
): CodexUsageWindow[] {
  const normalized = new Map(
    Object.entries(headers).map(([name, value]) => [name.toLowerCase(), value]),
  );

  return ["primary", "secondary"]
    .map((name) =>
      parseCodexUsageWindow({
        used_percent: normalized.get(`x-codex-${name}-used-percent`),
        window_minutes: normalized.get(`x-codex-${name}-window-minutes`),
        reset_at: normalized.get(`x-codex-${name}-reset-at`),
      }),
    )
    .filter((window): window is CodexUsageWindow => window !== undefined);
}

function formatResetInterval(resetsAtMs: number, now: number): string {
  const remainingMs = Math.max(0, resetsAtMs - now);
  const minutes = Math.floor(remainingMs / 60_000);
  if (minutes >= 24 * 60) return `${Math.floor(minutes / (24 * 60))}d`;
  if (minutes >= 60) return `${Math.floor(minutes / 60)}h`;
  return `${minutes}m`;
}

function formatCodexUsage(
  windows: readonly CodexUsageWindow[],
  now = Date.now(),
): string | undefined {
  const sorted = windows
    .map((window, index) => ({ window, index }))
    .sort(
      (a, b) =>
        (a.window.windowMinutes ?? Number.POSITIVE_INFINITY) -
          (b.window.windowMinutes ?? Number.POSITIVE_INFINITY) ||
        a.index - b.index,
    );
  if (sorted.length === 0) return undefined;

  return sorted
    .map(
      ({ window }) =>
        `${Math.floor(window.usedPercent)}%(${formatResetInterval(window.resetsAtMs, now)})`,
    )
    .join(" ");
}

export default function (pi: ExtensionAPI) {
  let codexUsageWindows: CodexUsageWindow[] = [];
  let requestFooterRender: (() => void) | undefined;

  const updateCodexUsage = (windows: CodexUsageWindow[]) => {
    if (windows.length === 0) return;
    codexUsageWindows = windows;
    requestFooterRender?.();
  };

  const refreshCodexUsage = async (ctx: ExtensionContext) => {
    codexUsageWindows = [];
    requestFooterRender?.();
    const provider = ctx.model?.provider;
    const windows = await fetchCodexUsage(ctx);
    if (ctx.model?.provider !== provider) return;
    codexUsageWindows = windows;
    requestFooterRender?.();
  };

  pi.on("after_provider_response", (event, ctx) => {
    if (ctx.mode !== "tui" || ctx.model?.provider !== "openai-codex") return;
    updateCodexUsage(parseCodexRateLimitHeaders(event.headers));
  });

  pi.on("provider_stream_event", (event, ctx) => {
    if (ctx.mode !== "tui" || event.provider !== "openai-codex") return;
    updateCodexUsage(parseCodexRateLimitEvent(event.data));
  });

  pi.on("model_select", async (_event, ctx) => {
    if (ctx.mode !== "tui" || !requestFooterRender) return;
    await refreshCodexUsage(ctx);
  });

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    codexUsageWindows = [];
    ctx.ui.setFooter((tui, _theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
      const renderFooter = () => tui.requestRender();
      requestFooterRender = renderFooter;
      const resetCountdownTimer = setInterval(renderFooter, 30_000);

      return {
        dispose() {
          unsubscribe();
          clearInterval(resetCountdownTimer);
          if (requestFooterRender === renderFooter) {
            requestFooterRender = undefined;
          }
        },
        invalidate() {},
        render(width: number): string[] {
          let cacheRead = 0;
          let cacheWrite = 0;
          let cost = 0;
          let latestCacheHitRate: number | undefined;

          for (const entry of ctx.sessionManager.getEntries()) {
            let usage:
              | {
                  input?: number;
                  cacheRead?: number;
                  cacheWrite?: number;
                  cost?: { total?: number };
                }
              | undefined;

            if (
              entry.type === "message" &&
              entry.message.role === "assistant"
            ) {
              const assistantUsage = entry.message.usage;
              usage = assistantUsage;
              const promptTokens =
                assistantUsage.input +
                assistantUsage.cacheRead +
                assistantUsage.cacheWrite;
              latestCacheHitRate =
                promptTokens > 0
                  ? (assistantUsage.cacheRead / promptTokens) * 100
                  : undefined;
            } else if (
              entry.type === "message" &&
              entry.message.role === "toolResult"
            ) {
              usage = entry.message.usage;
            } else if (
              entry.type === "branch_summary" ||
              entry.type === "compaction"
            ) {
              usage = entry.usage;
            }

            if (usage) {
              cacheRead += usage.cacheRead ?? 0;
              cacheWrite += usage.cacheWrite ?? 0;
              cost += usage.cost?.total ?? 0;
            }
          }

          const branch = footerData.getGitBranch();
          let topLine = ansi.cyan(projectName(ctx.cwd));
          if (branch) topLine += ` ${ansi.magenta(`[${branch}]`)}`;

          const leftParts: string[] = [];
          if (
            (cacheRead > 0 || cacheWrite > 0) &&
            latestCacheHitRate !== undefined
          ) {
            leftParts.push(ansi.red(`${latestCacheHitRate.toFixed(1)}%`));
          }

          const contextUsage = ctx.getContextUsage();
          const contextWindow =
            contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextDisplay =
            contextUsage?.percent == null
              ? `?/${formatTokens(contextWindow)}`
              : `${contextUsage.percent.toFixed(1)}%/${formatTokens(contextWindow)}`;
          leftParts.push(ansi.yellow(contextDisplay));

          const usingSubscription = ctx.model
            ? ctx.model.provider === "kimi-coding" ||
              (ctx.modelRegistry.isUsingOAuth(ctx.model) &&
                ctx.modelRegistry.getProvider(ctx.model.provider)?.auth.oauth
                  ?.isSubscription === true)
            : false;
          if (usingSubscription) {
            const codexUsage =
              ctx.model?.provider === "openai-codex"
                ? formatCodexUsage(codexUsageWindows)
                : undefined;
            leftParts.push(ansi.blue(codexUsage ?? "sub"));
          } else if (cost) {
            leftParts.push(ansi.blue(`$${cost.toFixed(2)}`));
          }

          let left = leftParts.join(" ");
          let leftWidth = visibleWidth(left);
          if (leftWidth > width) {
            left = truncateToWidth(left, width, "...");
            leftWidth = visibleWidth(left);
          }

          const modelName = ctx.model?.id ?? "no-model";
          let rightPlain = modelName;
          if (ctx.model?.reasoning) {
            const thinkingLevel = ctx.thinkingLevel ?? "off";
            rightPlain =
              thinkingLevel === "off"
                ? `${modelName} • thinking off`
                : `${modelName} • ${thinkingLevel}`;
          }

          const minimumPadding = 2;
          if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
            const withProvider = `(${ctx.model.provider}) ${rightPlain}`;
            if (
              leftWidth + minimumPadding + visibleWidth(withProvider) <=
              width
            )
              rightPlain = withProvider;
          }

          let bottomLine: string;
          const rightWidth = visibleWidth(rightPlain);
          if (leftWidth + minimumPadding + rightWidth <= width) {
            const padding = " ".repeat(width - leftWidth - rightWidth);
            bottomLine = left + padding + ansi.magenta(rightPlain);
          } else {
            const availableForRight = width - leftWidth - minimumPadding;
            if (availableForRight > 0) {
              const truncatedRight = truncateToWidth(
                ansi.magenta(rightPlain),
                availableForRight,
                "",
              );
              const padding = " ".repeat(
                Math.max(0, width - leftWidth - visibleWidth(truncatedRight)),
              );
              bottomLine = left + padding + truncatedRight;
            } else {
              bottomLine = left;
            }
          }

          const lines = [
            truncateToWidth(topLine, width, ansi.dim("...")),
            truncateToWidth(bottomLine, width, ""),
          ];

          const statuses = [...footerData.getExtensionStatuses().entries()]
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([, text]) => sanitizeStatusText(text));
          if (statuses.length > 0) {
            lines.push(
              truncateToWidth(statuses.join(" "), width, ansi.dim("...")),
            );
          }

          return lines;
        },
      };
    });

    await refreshCodexUsage(ctx);
  });
}
