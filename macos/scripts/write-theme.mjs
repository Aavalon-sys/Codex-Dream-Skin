import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const [mode, ...args] = process.argv.slice(2);

function valueFor(name, fallback = "") {
  const index = args.indexOf(`--${name}`);
  if (index < 0) return fallback;
  const value = args[index + 1];
  if (!value || value.startsWith("--")) throw new Error(`Missing value for --${name}`);
  return value;
}

function valuesFor(name) {
  const values = [];
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] !== `--${name}`) continue;
    const value = args[index + 1];
    if (!value || value.startsWith("--")) throw new Error(`Missing value for --${name}`);
    values.push(value);
  }
  return values;
}

function validateHex(value, name) {
  if (!/^#[0-9a-f]{6}$/i.test(value)) throw new Error(`${name} must be a six-digit hex color.`);
  return value.toLowerCase();
}

function hexToRgba(hex, alpha) {
  const value = Number.parseInt(hex.slice(1), 16);
  return `rgba(${value >> 16}, ${(value >> 8) & 255}, ${value & 255}, ${alpha})`;
}

function boundedText(value, fallback, max) {
  const text = String(value || fallback).trim().slice(0, max);
  return text || fallback;
}

async function validateAsset(outputDir, filename, maxBytes, label, extensions) {
  if (!filename) return null;
  if (path.basename(filename) !== filename || !extensions.test(filename)) {
    throw new Error(`${label} must be a supported filename inside the theme directory.`);
  }
  const assetPath = path.join(outputDir, filename);
  const stat = await fs.stat(assetPath);
  if (!stat.isFile() || stat.size < 1 || stat.size > maxBytes) {
    throw new Error(`${label} must be non-empty and no larger than ${maxBytes} bytes.`);
  }
  return filename;
}

async function atomicWrite(file, value) {
  await fs.mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
  const temporary = `${file}.${process.pid}.tmp`;
  try {
    await fs.writeFile(temporary, value, { mode: 0o600 });
    await fs.rename(temporary, file);
    await fs.chmod(file, 0o600);
  } finally {
    await fs.rm(temporary, { force: true }).catch(() => {});
  }
}

const outputDir = path.resolve(valueFor("output-dir", path.join(root, "assets")));
const themePath = path.join(outputDir, "theme.json");

if (mode === "reset-demo") {
  if (outputDir === path.join(root, "assets")) {
    throw new Error("Refusing to delete the bundled theme assets; pass a user --output-dir.");
  }
  await fs.rm(outputDir, { recursive: true, force: true });
  console.log("Restored the bundled Hazel preset.");
  process.exit(0);
}

if (mode !== "custom") {
  throw new Error("Usage: write-theme.mjs custom [options] | reset-demo --output-dir <dir>");
}

const image = await validateAsset(
  outputDir,
  path.basename(valueFor("image", "background.jpg")),
  16 * 1024 * 1024,
  "image",
  /\.(?:png|jpe?g|webp)$/i,
);
const stickerValue = valueFor("sticker", "");
const sticker = stickerValue
  ? await validateAsset(outputDir, stickerValue, 4 * 1024 * 1024, "sticker", /\.(?:png|webp)$/i)
  : null;

const name = boundedText(valueFor("name"), "我的 Codex Dream Skin", 80);
const brandSubtitle = boundedText(valueFor("brand-subtitle"), "CODEX DREAM SKIN", 80);
const tagline = boundedText(valueFor("tagline"), "把喜欢的画面变成可交互的 Codex 工作台。", 160);
const heroTitle = boundedText(valueFor("hero-title"), name, 80);
const heroSubtitle = boundedText(valueFor("hero-subtitle"), tagline, 180);
const quote = boundedText(valueFor("quote"), "MAKE SOMETHING WONDERFUL", 120);
const cornerQuotes = valuesFor("corner-quote")
  .map((item) => boundedText(item, "", 180))
  .filter(Boolean)
  .slice(0, 3);
if (!cornerQuotes.length) cornerQuotes.push(quote);
const statusText = boundedText(valueFor("status-text"), "DREAM SKIN ONLINE", 80);
const imagePosition = valueFor("image-position", "right");
if (!["left", "center", "right"].includes(imagePosition)) {
  throw new Error("image-position must be left, center, or right.");
}
const petSafeHeight = Number(valueFor("pet-safe-height", "0"));
if (!Number.isInteger(petSafeHeight) || petSafeHeight < 0 || petSafeHeight > 320) {
  throw new Error("pet-safe-height must be an integer from 0 to 320.");
}

const background = validateHex(valueFor("background", "#f3f2f2"), "background");
const panelAlt = validateHex(valueFor("panel-alt", "#e8ebea"), "panel-alt");
const accent = validateHex(valueFor("accent", "#5c968e"), "accent");
const accentAlt = validateHex(valueFor("accent-alt", accent), "accent-alt");
const secondary = validateHex(valueFor("secondary", "#d3d3d3"), "secondary");
const highlight = validateHex(valueFor("highlight", "#d89ba9"), "highlight");
const text = validateHex(valueFor("text", "#26312f"), "text");
const muted = validateHex(valueFor("muted", "#65716f"), "muted");

const custom = {
  schemaVersion: 1,
  id: `custom-${Date.now()}`,
  name,
  brandSubtitle,
  heroTitle,
  heroSubtitle,
  tagline,
  projectPrefix: "选择项目 · ",
  projectLabel: "🩶  选择项目",
  statusText,
  quote,
  cornerQuotes,
  image,
  ...(sticker ? { sticker } : {}),
  imagePosition,
  petSafeArea: { edge: "bottom", minHeight: petSafeHeight },
  colors: {
    background,
    panel: "rgba(255, 255, 255, 0.82)",
    panelAlt,
    accent,
    accentAlt,
    secondary,
    highlight,
    text,
    muted,
    line: hexToRgba(accent, 0.25),
  },
  darkColors: {
    background: "#171a1a",
    panel: "rgba(31, 38, 37, 0.90)",
    panelAlt: "#29302f",
    accent: "#8fbfb6",
    accentAlt: "#a5cec6",
    secondary,
    highlight: "#d8a0ad",
    text: "#f2f4f3",
    muted: "#b7c1bf",
    line: "rgba(143, 191, 182, 0.30)",
  },
};

await atomicWrite(themePath, `${JSON.stringify(custom, null, 2)}\n`);
console.log(`Saved custom theme “${custom.name}”.`);
