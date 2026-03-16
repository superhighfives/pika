#!/usr/bin/env tsx
/**
 * Pika marketing asset generator.
 *
 * Usage:
 *   npx tsx build/marketing/generate.ts --version <version> [--capture] [--web] [--figma] [--all]
 *
 * Flags:
 *   --version  Required. Version string, e.g. 1.3.0 or 1.2.0-beta1.
 *   --capture  Run capture loop via capture.sh (requires Pika running).
 *   --web      Composite source PNGs into website JPGs.
 *   --figma    Copy shadow-trimmed PNGs to figma/ output folder.
 *   --all      Run capture, web, and figma in sequence.
 *
 * Output: pika-releases/Marketing/v<version>/
 */

import { execSync } from "child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync } from "fs";
import { dirname, join, resolve } from "path";
import sharp from "sharp";

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const SCRIPT_DIR = dirname(new URL(import.meta.url).pathname);
const REPO_ROOT = resolve(SCRIPT_DIR, "../..");
const WORKSPACE_ROOT = resolve(REPO_ROOT, "..");
const SOURCE_DIR = join(SCRIPT_DIR, "source");
const RELEASES_DIR = join(WORKSPACE_ROOT, "pika-releases", "Marketing");

// ---------------------------------------------------------------------------
// Manifest
// ---------------------------------------------------------------------------

interface Shot {
  file: string;
  fg: string;
  bg: string;
  appearance: "light" | "dark";
  history: "show" | "hide";
}

interface Manifest {
  shots: Shot[];
  web: { dark: string[]; light: string[] };
  figma: Record<string, string>;
}

const manifest: Manifest = JSON.parse(
  readFileSync(join(SCRIPT_DIR, "manifest.json"), "utf8")
);

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

function flag(name: string): boolean {
  return args.includes(name);
}

function arg(name: string): string | undefined {
  const idx = args.indexOf(name);
  return idx !== -1 ? args[idx + 1] : undefined;
}

const version = arg("--version");
if (!version) {
  console.error("Error: --version is required");
  process.exit(1);
}

const runCapture = flag("--capture") || flag("--all");
const runWeb = flag("--web") || flag("--all");
const runFigma = flag("--figma") || flag("--all");

if (!runCapture && !runWeb && !runFigma) {
  console.error("Error: specify at least one of --capture, --web, --figma, or --all");
  process.exit(1);
}

const OUTPUT_DIR = join(RELEASES_DIR, `v${version}`);
const FIGMA_DIR = join(OUTPUT_DIR, "figma");

// ---------------------------------------------------------------------------
// Capture
// ---------------------------------------------------------------------------

async function runCaptureStep(): Promise<void> {
  console.log("\n── Capture ──────────────────────────────────────");
  mkdirSync(SOURCE_DIR, { recursive: true });

  const captureScript = join(SCRIPT_DIR, "capture.sh");

  for (const shot of manifest.shots) {
    const outputPath = join(SOURCE_DIR, shot.file);
    const cmd = `"${captureScript}" "${outputPath}" "${shot.fg}" "${shot.bg}" "${shot.appearance}" "${shot.history}"`;
    console.log(`  ${shot.file}`);
    execSync(cmd, { stdio: "inherit" });
  }
}

// ---------------------------------------------------------------------------
// Web composite
// ---------------------------------------------------------------------------

const CANVAS_WIDTH = 2380;
const CANVAS_HEIGHT = 838;

// Layout: left (x=-30, y=54), center (x=893, y=0), right (x=1820, y=54)
const WINDOW_POSITIONS = [
  { left: -30, top: 54 },
  { left: 893, top: 0 },
  { left: 1820, top: 54 },
];

const BACKGROUNDS: Record<"dark" | "light", { r: number; g: number; b: number }> = {
  dark:  { r: 26,  g: 26,  b: 26  },
  light: { r: 255, g: 255, b: 255 },
};

async function compositeWeb(mode: "dark" | "light"): Promise<void> {
  const files = manifest.web[mode];
  const bg = BACKGROUNDS[mode];

  const trimmed = await Promise.all(
    files.map((f) =>
      sharp(join(SOURCE_DIR, f))
        .trim()
        .toBuffer({ resolveWithObject: true })
    )
  );

  const composites = trimmed.map(({ data, info }, i) => ({
    input: data,
    left: Math.max(0, WINDOW_POSITIONS[i].left),
    top: WINDOW_POSITIONS[i].top,
  }));

  mkdirSync(OUTPUT_DIR, { recursive: true });

  const base2x = sharp({
    create: {
      width: CANVAS_WIDTH,
      height: CANVAS_HEIGHT,
      channels: 3,
      background: bg,
    },
  });

  const jpg2x = join(OUTPUT_DIR, `pika-screenshot-${mode}@2x.jpg`);
  const jpg1x = join(OUTPUT_DIR, `pika-screenshot-${mode}.jpg`);

  const composited = await base2x
    .composite(composites)
    .jpeg({ quality: 95 })
    .toBuffer();

  await sharp(composited).toFile(jpg2x);
  console.log(`  → ${jpg2x}`);

  await sharp(composited)
    .resize(Math.round(CANVAS_WIDTH / 2), Math.round(CANVAS_HEIGHT / 2))
    .jpeg({ quality: 95 })
    .toFile(jpg1x);
  console.log(`  → ${jpg1x}`);
}

async function runWebStep(): Promise<void> {
  console.log("\n── Web composites ───────────────────────────────");
  await compositeWeb("dark");
  await compositeWeb("light");
}

// ---------------------------------------------------------------------------
// Figma export
// ---------------------------------------------------------------------------

async function runFigmaStep(): Promise<void> {
  console.log("\n── Figma exports ────────────────────────────────");
  mkdirSync(FIGMA_DIR, { recursive: true });

  for (const [key, file] of Object.entries(manifest.figma)) {
    const src = join(SOURCE_DIR, file);
    const dest = join(FIGMA_DIR, `${key}.png`);

    await sharp(src).trim().toFile(dest);
    console.log(`  ${key}.png  ← ${file}`);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  console.log(`Pika marketing assets  v${version}`);
  console.log(`Output: ${OUTPUT_DIR}`);

  if (runCapture) await runCaptureStep();
  if (runWeb)     await runWebStep();
  if (runFigma)   await runFigmaStep();

  console.log("\nDone.");
})();
