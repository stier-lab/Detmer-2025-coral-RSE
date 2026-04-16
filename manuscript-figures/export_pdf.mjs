import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const inputPath = path.join(__dirname, 'fig1_panel_b.html');
const outputPdf = path.join(__dirname, 'fig1_panel_b.pdf');
const outputPng = path.join(__dirname, 'fig1_panel_b_300dpi.png');

const browser = await chromium.launch();
const page = await browser.newPage();

// 180mm wide, aspect ratio from viewBox 740:540 = height ~131.4mm
const widthMM = 180;
const heightMM = Math.round((540 / 740) * widthMM);

// For PDF: set viewport to match exact mm at 96dpi (1mm = 3.7795px)
const pxPerMM = 3.7795;
const vpWidth = Math.round(widthMM * pxPerMM);
const vpHeight = Math.round(heightMM * pxPerMM);

await page.setViewportSize({ width: vpWidth, height: vpHeight });
await page.goto(`file://${inputPath}`, { waitUntil: 'networkidle' });

// Override styles for PDF export: remove padding, fill page
await page.addStyleTag({
  content: `
    body { padding: 0 !important; margin: 0 !important; background: #FAFAF7 !important; }
    svg { width: 100vw !important; height: 100vh !important; }
  `
});
await page.waitForTimeout(2000);

// PDF
await page.pdf({
  path: outputPdf,
  width: `${widthMM}mm`,
  height: `${heightMM}mm`,
  printBackground: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 },
});
console.log(`PDF: ${outputPdf} (${widthMM}×${heightMM}mm)`);

// 300 DPI PNG
const dpi = 300;
const pngW = Math.round(widthMM / 25.4 * dpi);
const pngH = Math.round(heightMM / 25.4 * dpi);

await page.setViewportSize({ width: pngW, height: pngH });
await page.addStyleTag({
  content: `
    body { padding: 0 !important; margin: 0 !important; }
    svg { width: 100vw !important; height: 100vh !important; }
  `
});
await page.waitForTimeout(1000);
await page.screenshot({ path: outputPng, fullPage: false });
console.log(`PNG: ${outputPng} (${pngW}×${pngH}px = ${dpi}dpi at ${widthMM}×${heightMM}mm)`);

await browser.close();
