#!/usr/bin/env npx tsx
/**
 * Benchmark the effect of each CLAUDE.md rule by ablating one rule at a time
 * and running Claude Code with a fixed coding prompt. Compare outputs to see
 * what each rule actually does.
 *
 * Usage: npx tsx index.ts [--dry-run]
 *
 * Results are saved to ./results/<variant>/
 *   output.md  - full claude response
 *   code.ts    - extracted TypeScript code block
 *   meta.json  - metadata (rule removed, timestamp)
 */

import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const CLAUDE_MD_SOURCE = resolve(__dirname, "../../dotfiles/dot_claude/CLAUDE.md");
const GLOBAL_CLAUDE_MD = join(homedir(), ".claude", "CLAUDE.md");
const BACKUP_PATH = GLOBAL_CLAUDE_MD + ".benchmark-backup";
const RESULTS_DIR = join(__dirname, "results");

// Tools disabled so we get code in the response text, not written to disk.
// This makes extraction and diffing straightforward.
const PROMPT =
  "Write TypeScript code to render a histogram in the terminal. " +
  "The domain (x-axis) should be horizontal with category labels. " +
  "The range (y-axis) should be vertical, with bars drawn upward using stacked characters. " +
  "Provide a renderHistogram(data: Record<string, number>) function and a main() that demonstrates it with sample data.";

interface Rule {
  name: string;
  slug: string;
  startLine: number;
  // exclusive end: lines[startLine..endLine) belong to this rule
  endLine: number;
}

function parseRules(content: string): Rule[] {
  const lines = content.split("\n");
  const rules: Rule[] = [];

  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith("- ")) continue;

    // Consume all indented continuation lines (e.g. code blocks inside a bullet)
    let end = i + 1;
    while (end < lines.length && /^[ \t]/.test(lines[end])) {
      end++;
    }

    const nameMatch = lines[i].match(/^- \*\*([^*]+)\*\*/);
    const rawName = nameMatch ? nameMatch[1].trim() : lines[i].slice(2).trim();
    const slug = rawName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/-$/, "");

    rules.push({ name: rawName, slug, startLine: i, endLine: end });
    i = end - 1;
  }

  return rules;
}

function applyAblation(content: string, rule: Rule): string {
  const lines = content.split("\n");
  lines.splice(rule.startLine, rule.endLine - rule.startLine);
  return lines.join("\n");
}

function extractCode(output: string): string | null {
  // Grab the largest typescript/ts code block (avoids capturing filename-only blocks)
  const matches = [...output.matchAll(/```(?:typescript|ts)\n([\s\S]*?)```/g)];
  if (matches.length === 0) return null;
  return matches.reduce((best, m) => m[1].length > best[1].length ? m : best)[1];
}

function runVariant(claudeMd: string, label: string, dryRun: boolean): { output: string; code: string | null } {
  if (existsSync(GLOBAL_CLAUDE_MD)) {
    renameSync(GLOBAL_CLAUDE_MD, BACKUP_PATH);
  }

  try {
    writeFileSync(GLOBAL_CLAUDE_MD, claudeMd);

    if (dryRun) {
      const output = `[dry-run] Would run claude for: ${label}`;
      return { output, code: null };
    }

    const tmpDir = mkdtempSync(join(tmpdir(), "claude-benchmark-"));
    try {
      const result = spawnSync(
        "claude",
        ["--print", "--tools", "", "--no-session-persistence", PROMPT],
        { cwd: tmpDir, encoding: "utf-8", timeout: 600_000 }
      );

      if (result.error) throw result.error;
      const output = result.stdout ?? "";
      return { output, code: extractCode(output) };
    } finally {
      rmSync(tmpDir, { recursive: true, force: true });
    }
  } finally {
    if (existsSync(BACKUP_PATH)) {
      renameSync(BACKUP_PATH, GLOBAL_CLAUDE_MD);
    } else {
      rmSync(GLOBAL_CLAUDE_MD, { force: true });
    }
  }
}

function saveResult(dir: string, output: string, code: string | null, ruleName: string | null) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "output.md"), output);
  if (code) writeFileSync(join(dir, "code.ts"), code);
  writeFileSync(
    join(dir, "meta.json"),
    JSON.stringify({ ruleRemoved: ruleName, timestamp: new Date().toISOString() }, null, 2)
  );
}

// ---- main ----

const dryRun = process.argv.includes("--dry-run");
if (dryRun) console.log("[dry-run mode — skipping actual claude invocations]\n");

const content = readFileSync(CLAUDE_MD_SOURCE, "utf-8");
const rules = parseRules(content);

console.log(`Found ${rules.length} rules to ablate:`);
rules.forEach((r, i) => console.log(`  ${i + 1}. ${r.name}`));
console.log();

mkdirSync(RESULTS_DIR, { recursive: true });

function isDone(dir: string): boolean {
  return existsSync(join(dir, "meta.json"));
}

// Baseline: full CLAUDE.md
const baselineDir = join(RESULTS_DIR, "baseline");
console.log("(1 / " + (rules.length + 1) + ") baseline");
if (isDone(baselineDir)) {
  console.log("  skipped (already done)\n");
} else {
  const baselineResult = runVariant(content, "baseline", dryRun);
  saveResult(baselineDir, baselineResult.output, baselineResult.code, null);
  console.log(`  code extracted: ${baselineResult.code ? "yes" : "no"}\n`);
}

// Ablations
for (let i = 0; i < rules.length; i++) {
  const rule = rules[i];
  const variantDir = join(RESULTS_DIR, `no-${rule.slug}`);
  console.log(`(${i + 2} / ${rules.length + 1}) no-${rule.slug}`);
  if (isDone(variantDir)) {
    console.log("  skipped (already done)\n");
    continue;
  }
  const variant = applyAblation(content, rule);
  const result = runVariant(variant, rule.name, dryRun);
  saveResult(variantDir, result.output, result.code, rule.name);
  console.log(`  code extracted: ${result.code ? "yes" : "no"}\n`);
}

console.log("Done. Results in:", RESULTS_DIR);
console.log();
console.log("Suggested diffs:");
for (const rule of rules) {
  console.log(`  diff results/baseline/code.ts results/no-${rule.slug}/code.ts`);
}
