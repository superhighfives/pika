#!/usr/bin/env tsx
/**
 * Pika marketing asset generator.
 *
 * Usage:
 *   npx tsx build/marketing/generate.ts --version <version> [--app <path>] [--capture] [--web] [--figma] [--all]
 *
 * Flags:
 *   --version  Required. Version string, e.g. 1.3.0 or 1.2.0-beta1.
 *   --app      Optional. Path to Pika.app. Overrides auto-detection.
 *   --capture  Launch Pika.app, capture all shots, quit.
 *   --web      Composite source PNGs into website JPGs (@2x + @1x).
 *   --figma    Copy shadow-trimmed PNGs to figma/ output folder.
 *   --all      Run capture, web, and figma in sequence.
 *
 * Pika.app resolution order:
 *   1. --app <path> if provided
 *   2. pika-releases/Production Exports/Pika * (v<version>)/Pika.app
 *   3. Whatever Pika is registered system-wide (fallback)
 *
 * Output: pika-releases/Marketing/v<version>/
 */

import { execSync, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import sharp from "sharp";

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const SCRIPT_DIR = dirname(new URL(import.meta.url).pathname);
const REPO_ROOT = resolve(SCRIPT_DIR, "../..");
const WORKSPACE_ROOT = resolve(REPO_ROOT, "..");
const SOURCE_DIR = join(SCRIPT_DIR, "source");
const EXPORTS_DIR = join(WORKSPACE_ROOT, "pika-releases", "Production Exports");
const RELEASES_DIR = join(WORKSPACE_ROOT, "pika-releases", "Marketing");

// ---------------------------------------------------------------------------
// Manifest
// ---------------------------------------------------------------------------

interface Shot {
  window?: "about" | "help" | "preferences" | "splash";
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
// App detection
// ---------------------------------------------------------------------------

function findExportedApp(ver: string): string | undefined {
  if (!existsSync(EXPORTS_DIR)) return undefined;
  const match = readdirSync(EXPORTS_DIR).find((entry) =>
    entry.includes(`(v${ver})`)
  );
  if (!match) return undefined;
  const appPath = join(EXPORTS_DIR, match, "Pika.app");
  return existsSync(appPath) ? appPath : undefined;
}

const pikaApp = arg("--app") ?? findExportedApp(version);

// ---------------------------------------------------------------------------
// Capture
// ---------------------------------------------------------------------------

async function runCaptureStep(): Promise<void> {
  console.log("\n── Capture ──────────────────────────────────────");
  mkdirSync(SOURCE_DIR, { recursive: true });

  if (pikaApp) {
    console.log(`  App: ${pikaApp}`);
    console.log("  Quitting any existing Pika…");
    spawnSync("pkill", ["-x", "Pika"], { stdio: "pipe" });
    await sleep(500);
    console.log("  Launching Pika…");
    spawnSync("open", ["-a", pikaApp], { stdio: "inherit" });
    // Allow Pika to fully initialise before sending URL triggers
    await sleep(2000);
  } else {
    console.log("  App: system Pika (no export found for this version)");
  }

  const captureScript = join(SCRIPT_DIR, "capture.sh");
  const env = { ...process.env, ...(pikaApp ? { PIKA_APP: pikaApp } : {}) };

  for (const shot of manifest.shots) {
    const outputPath = join(SOURCE_DIR, shot.file);
    const cmd = `"${captureScript}" "${outputPath}" "${shot.fg}" "${shot.bg}" "${shot.appearance}" "${shot.history}" "${shot.window ?? "main"}"`;
    console.log(`  ${shot.file}`);
    execSync(cmd, { stdio: "inherit", env });
  }

  if (pikaApp) {
    console.log("  Quitting Pika…");
    spawnSync("osascript", ["-e", 'quit app "Pika"'], { stdio: "inherit" });
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Web composite
// ---------------------------------------------------------------------------

// Canvas dimensions match the website @2x asset size.
// screencapture gives 960x600px windows (480x300pt at @2x Retina).
// Windows are placed at full captured size on the @2x canvas.
// @1x output is a 50% resize of the @2x canvas.
const CANVAS_WIDTH = 2380;
const CANVAS_HEIGHT = 838;

// Three-window fan layout on the @2x canvas (2380x838).
// Center window is in front (composited last), side windows partially off-screen.
// Draw order: left → right → center (so center appears on top).
const WINDOW_POSITIONS = [
  { left: -50, top: 160 },  // left  (index 0 in manifest.web)
  { left: 710, top: 80  },  // center (index 1)
  { left: 1470, top: 160 }, // right  (index 2)
];
const COMPOSITE_ORDER = [0, 2, 1]; // draw left and right first, center last

const BACKGROUNDS: Record<"dark" | "light", { r: number; g: number; b: number }> = {
  dark:  { r: 26,  g: 26,  b: 26  },
  light: { r: 255, g: 255, b: 255 },
};

async function compositeWeb(mode: "dark" | "light"): Promise<void> {
  const files = manifest.web[mode];
  const bg = BACKGROUNDS[mode];

  // Build composites in COMPOSITE_ORDER so center window renders on top.
  const composites: Parameters<ReturnType<typeof sharp>["composite"]>[0] = [];
  for (const idx of COMPOSITE_ORDER) {
    const file = join(SOURCE_DIR, files[idx]);
    let left = WINDOW_POSITIONS[idx].left;
    const top = WINDOW_POSITIONS[idx].top;

    let input: Buffer;
    if (left < 0) {
      // Crop off the portion that would be off-screen to the left.
      const meta = await sharp(file).metadata();
      input = await sharp(file)
        .extract({ left: -left, top: 0, width: (meta.width ?? 960) + left, height: meta.height ?? 600 })
        .toBuffer();
      left = 0;
    } else {
      input = await sharp(file).toBuffer();
    }

    composites.push({ input, left, top });
  }

  mkdirSync(OUTPUT_DIR, { recursive: true });

  const composited = await sharp({
    create: { width: CANVAS_WIDTH, height: CANVAS_HEIGHT, channels: 3, background: bg },
  })
    .composite(composites)
    .jpeg({ quality: 95 })
    .toBuffer();

  const jpg2x = join(OUTPUT_DIR, `pika-screenshot-${mode}@2x.jpg`);
  const jpg1x = join(OUTPUT_DIR, `pika-screenshot-${mode}.jpg`);

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

// Remove macOS window shadow from a PNG.
// screencapture includes the shadow as semi-transparent pixels outside the window frame.
// sharp's default .trim() only removes fully-transparent pixels (alpha === 0), leaving
// residual shadow. This function first zeros out any pixel with alpha < 200, then trims.
async function removeShadow(src: string): Promise<Buffer> {
  const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width, height, channels } = info;
  for (let i = 0; i < data.length; i += channels) {
    if (data[i + 3] < 200) {
      data[i] = 0; data[i + 1] = 0; data[i + 2] = 0; data[i + 3] = 0;
    }
  }
  return sharp(Buffer.from(data), { raw: { width, height, channels } }).trim().png().toBuffer();
}

async function runFigmaStep(): Promise<void> {
  console.log("\n── Figma exports ────────────────────────────────");
  mkdirSync(FIGMA_DIR, { recursive: true });

  for (const [key, file] of Object.entries(manifest.figma)) {
    const src = join(SOURCE_DIR, file);
    const dest = join(FIGMA_DIR, `${key}.png`);
    const buf = await removeShadow(src);
    await sharp(buf).toFile(dest);
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
