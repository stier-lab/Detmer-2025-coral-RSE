// Export Figure 1 to PDF (180mm wide) and 600dpi PNG
// Usage: node export.mjs

import { chromium } from 'playwright';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const html = path.join(__dirname, 'fig1.html');

const browser = await chromium.launch();
const page = await browser.newPage();

// Figure dimensions: viewBox 740×762 → 180mm wide, height scales proportionally
const W_MM = 180;
const H_MM = Math.round(762 / 740 * W_MM); // ~185mm

const scale = 4;
const vpW = Math.round(W_MM * 3.7795 * scale);
const vpH = Math.round(H_MM * 3.7795 * scale);

await page.setViewportSize({ width: vpW, height: vpH });
await page.goto('file://' + html, { waitUntil: 'networkidle' });
await page.addStyleTag({ content: `
  body { margin:0!important; padding:0!important; height:100vh; display:flex; align-items:center; justify-content:center; }
  svg { width:100vw!important; height:100vh!important; }
`});
await page.waitForTimeout(2000);

// PDF
const pdf = path.join(__dirname, 'fig1.pdf');
await page.pdf({
  path: pdf, width: W_MM + 'mm', height: H_MM + 'mm',
  printBackground: true, margin: { top: 0, right: 0, bottom: 0, left: 0 },
});

// 600 DPI PNG
const dpi = 600;
const pngW = Math.round(W_MM / 25.4 * dpi);
const pngH = Math.round(H_MM / 25.4 * dpi);
await page.setViewportSize({ width: pngW, height: pngH });
await page.addStyleTag({ content: `
  body { margin:0!important; padding:0!important; height:100vh; display:flex; align-items:center; justify-content:center; }
  svg { width:100vw!important; height:100vh!important; }
`});
await page.waitForTimeout(1000);
const png = path.join(__dirname, 'fig1_600dpi.png');
await page.screenshot({ path: png });

console.log(`PDF: ${pdf} (${W_MM}×${H_MM}mm)`);
console.log(`PNG: ${png} (${pngW}×${pngH}px, ${dpi}dpi)`);
await browser.close();
