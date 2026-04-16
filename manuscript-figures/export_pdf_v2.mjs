import { chromium } from 'playwright';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const html = path.join(__dirname, 'fig1_panel_b.html');
const pdf = path.join(__dirname, 'fig1_panel_b.pdf');

const browser = await chromium.launch();
const page = await browser.newPage();

// Match the SVG's natural aspect: 740:600
const W_MM = 180;
const H_MM = Math.round(600/740 * W_MM); // 146mm

// Set viewport to exactly match the SVG at 4x for crisp rendering
const scale = 4;
const vpW = Math.round(W_MM * 3.7795 * scale);
const vpH = Math.round(H_MM * 3.7795 * scale);

await page.setViewportSize({ width: vpW, height: vpH });
await page.goto('file://' + html, { waitUntil: 'networkidle' });

// Inject CSS to make SVG fill viewport exactly, no padding
await page.addStyleTag({ content: `
  body { margin:0 !important; padding:0 !important; display:flex; justify-content:center; align-items:center; height:100vh; background:#FAFAF7; }
  svg { width:100vw !important; height:100vh !important; }
`});
await page.waitForTimeout(2000);

// Generate PDF
await page.pdf({
  path: pdf,
  width: W_MM + 'mm',
  height: H_MM + 'mm',
  printBackground: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 },
});

// Also generate high-res PNG
const pngDpi = 600; // 600 DPI for Nature
const pngW = Math.round(W_MM / 25.4 * pngDpi);
const pngH = Math.round(H_MM / 25.4 * pngDpi);
await page.setViewportSize({ width: pngW, height: pngH });
await page.addStyleTag({ content: `
  body { margin:0 !important; padding:0 !important; display:flex; justify-content:center; align-items:center; height:100vh; background:#FAFAF7; }
  svg { width:100vw !important; height:100vh !important; }
`});
await page.waitForTimeout(1000);
await page.screenshot({ path: path.join(__dirname, 'fig1_panel_b_600dpi.png') });

console.log(`PDF: ${pdf} (${W_MM}×${H_MM}mm)`);
console.log(`PNG: fig1_panel_b_600dpi.png (${pngW}×${pngH}px, ${pngDpi}dpi)`);

await browser.close();
