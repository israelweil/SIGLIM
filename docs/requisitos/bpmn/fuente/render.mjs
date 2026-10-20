// Valida (bpmn-moddle) y renderiza (bpmn-js en Chromium) cada .bpmn de una carpeta a SVG y PNG.
// Uso: node render.mjs <carpeta_bpmn> <carpeta_figuras>
import { chromium } from 'playwright-core';
import BpmnModdle from 'bpmn-moddle';
import fs from 'node:fs';
import path from 'node:path';

const [, , dirIn, dirOut] = process.argv;
fs.mkdirSync(dirOut, { recursive: true });
// Chromium: variable CHROMIUM_PATH o la ruta preinstalada de Playwright.
const CHROMIUM = process.env.CHROMIUM_PATH || '/opt/pw-browsers/chromium';
const viewer = fs.readFileSync('node_modules/bpmn-js/dist/bpmn-navigated-viewer.production.min.js', 'utf8');
const css = ['diagram-js.css', 'bpmn-js.css', 'bpmn-font/css/bpmn.css']
  .map(f => fs.readFileSync(path.join('node_modules/bpmn-js/dist/assets', f), 'utf8')).join('\n');

const moddle = new BpmnModdle();
const browser = await chromium.launch({ executablePath: CHROMIUM, headless: false, args: ['--headless=new', '--no-sandbox'] });
const page = await browser.newPage({ deviceScaleFactor: 2 });
await page.setContent(`<html><head><style>${css} body{margin:0;background:#fff} #c{width:4000px;height:2000px}</style></head>
<body><div id="c"></div><script>${viewer}</script></body></html>`);

let errores = 0;
for (const f of fs.readdirSync(dirIn).filter(f => f.endsWith('.bpmn')).sort()) {
  const xml = fs.readFileSync(path.join(dirIn, f), 'utf8');
  const { warnings } = await moddle.fromXML(xml);
  if (warnings.length) { errores++; console.log('ADVERTENCIAS', f, warnings.map(w => w.message)); }
  const res = await page.evaluate(async (xml) => {
    document.getElementById('c').innerHTML = '';
    const v = new BpmnJS({ container: '#c' });
    const r = await v.importXML(xml);
    const { svg } = await v.saveSVG();
    return { svg, warnings: r.warnings.map(w => w.message) };
  }, xml);
  if (res.warnings.length) { errores++; console.log('IMPORTACION', f, res.warnings); }
  const base = f.replace('.bpmn', '');
  fs.writeFileSync(path.join(dirOut, base + '.svg'), res.svg);
  const p2 = await browser.newPage({ deviceScaleFactor: 2 });
  await p2.setContent(`<html><body style="margin:0;background:#fff">${res.svg}</body></html>`);
  const el = await p2.$('svg');
  await el.screenshot({ path: path.join(dirOut, base + '.png') });
  await p2.close();
  console.log('ok', base);
}
await browser.close();
process.exit(errores ? 1 : 0);
