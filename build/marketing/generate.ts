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

// Drop shadow parameters — declared here so WINDOW_POSITIONS can reference them.
const SHADOW_OFFSET_Y = 10;   // downward shift in px
const SHADOW_BLUR     = 10;   // gaussian sigma
const SHADOW_OPACITY  = 0.15; // 0–1

// Three-window fan layout on the @2x canvas (2380x838).
// Center window is in front (composited last), side windows partially off-screen.
// Draw order: left → right → center (so center appears on top).
// Positions refer to the visual window corner (shadow padding is added internally).
// Side windows are inset by SHADOW_BLUR * 2 so the outer shadow fades to the canvas edge
// rather than clipping. Center window remains horizontally centred on the canvas.
const SHADOW_EDGE_PAD = SHADOW_BLUR * 2;
const WINDOW_POSITIONS = [
  { left: SHADOW_EDGE_PAD,                      top: 160 },  // left
  { left: 710,                                  top: 80  },  // center — centred on 2380px canvas
  { left: CANVAS_WIDTH - 960 - SHADOW_EDGE_PAD, top: 160 },  // right
];
const COMPOSITE_ORDER = [0, 2, 1]; // draw left and right first, center last

const BACKGROUNDS: Record<"dark" | "light", { r: number; g: number; b: number }> = {
  dark:  { r: 26,  g: 26,  b: 26  },
  light: { r: 255, g: 255, b: 255 },
};

// Add a consistent programmatic drop shadow to a window image.
// Returns the image buffer with shadow included, plus the uniform padding added on each side.
//
// Why grayscale for the blur: Sharp uses premultiplied alpha internally for gaussblur.
// Blurring pure black (0,0,0) on transparent (0,0,0,0) gives identical premultiplied
// values (0,0,0) in both regions — the Gaussian has nothing to spread, producing a
// hard edge. Extracting the alpha channel as single-channel greyscale and blurring that
// directly avoids premultiplied alpha entirely, giving a proper Gaussian gradient.
async function withDropShadow(buf: Buffer): Promise<{ image: Buffer; padLeft: number; padTop: number }> {

  const meta = await sharp(buf).metadata();
  const w = meta.width ?? 960;
  const h = meta.height ?? 600;

  // All sides need 2× SHADOW_BLUR so the Gaussian (σ=SHADOW_BLUR) doesn't clip at the canvas edge
  // (at 1σ the shadow is still ~61% intensity; at 2σ it's ~14%, negligible).
  // Bottom gets an extra SHADOW_OFFSET_Y since the shadow is shifted down.
  const padLeft   = SHADOW_BLUR * 2;
  const padTop    = SHADOW_BLUR * 2;
  const padRight  = SHADOW_BLUR * 2;
  const padBottom = SHADOW_BLUR * 2 + SHADOW_OFFSET_Y;
  const totalW = w + padLeft + padRight;
  const totalH = h + padTop + padBottom;

  // 1. Extract the window's alpha channel as single-channel greyscale.
  const windowAlpha = await sharp(buf).extractChannel(3).toBuffer();

  // 2. Extend the alpha mask with black padding (shadow shifted down), then blur.
  //    Using extend() on the greyscale image directly and blurring in a second step
  //    avoids RGB canvas compositing quirks and pipeline ordering issues.
  const alphaPadded = await sharp(windowAlpha)
    .extend({
      top:    padTop + SHADOW_OFFSET_Y,   // extra offset pushes shadow down in the blur canvas
      bottom: SHADOW_BLUR * 2,
      left:   padLeft,
      right:  padRight,
      background: { r: 0, g: 0, b: 0 },
    })
    .png()
    .toBuffer();

  const { data: blurredGrey, info: blurInfo } = await sharp(alphaPadded)
    .blur(SHADOW_BLUR)
    .raw()
    .toBuffer({ resolveWithObject: true });

  // 3. Build RGBA shadow: R=G=B=0 (black), A = blurred grey × SHADOW_OPACITY.
  // Use blurInfo.channels to stride correctly — Sharp may output 1, 2, or 3 channels
  // depending on how it encoded the padded PNG; always take the first channel.
  const ch = blurInfo.channels;
  const shadowData = Buffer.alloc(totalW * totalH * 4, 0);
  for (let i = 0; i < totalW * totalH; i++) {
    shadowData[i * 4 + 3] = Math.round((blurredGrey[i * ch] as number) * SHADOW_OPACITY);
  }
  const shadow = await sharp(shadowData, { raw: { width: totalW, height: totalH, channels: 4 } })
    .png()
    .toBuffer();

  // 4. Composite the clean window over the shadow at the padded position.
  const result = await sharp(shadow)
    .composite([{ input: buf, left: padLeft, top: padTop }])
    .png()
    .toBuffer();

  return { image: result, padLeft, padTop };
}

async function compositeWeb(mode: "dark" | "light"): Promise<void> {
  const files = manifest.web[mode];
  const bg = BACKGROUNDS[mode];

  // Build composites in COMPOSITE_ORDER so center window renders on top.
  const composites: Parameters<ReturnType<typeof sharp>["composite"]>[0] = [];
  for (const idx of COMPOSITE_ORDER) {
    const src = join(SOURCE_DIR, files[idx]);

    // Remove macOS-captured shadow, then apply a consistent programmatic shadow.
    const cleaned = await removeShadow(src);
    const { image: shadowed, padLeft, padTop } = await withDropShadow(cleaned);

    // Adjust position so the window chrome lands at WINDOW_POSITIONS[idx].
    let left = WINDOW_POSITIONS[idx].left - padLeft;
    const top = WINDOW_POSITIONS[idx].top - padTop;

    let input: Buffer;
    if (left < 0) {
      // Crop the hidden left portion (shadow padding + off-screen shift).
      const meta = await sharp(shadowed).metadata();
      input = await sharp(shadowed)
        .extract({ left: -left, top: 0, width: (meta.width ?? 0) + left, height: meta.height ?? 0 })
        .toBuffer();
      left = 0;
    } else {
      input = shadowed;
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
