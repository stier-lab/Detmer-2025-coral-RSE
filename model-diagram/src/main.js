import { initDiagram } from './render.js';
import { initInteractions } from './interactions.js';
import './styles.css';

document.addEventListener('DOMContentLoaded', () => {
  const svgEl = document.getElementById('diagram');
  if (!svgEl) {
    console.error('SVG element #diagram not found');
    return;
  }

  initDiagram(svgEl);
  initInteractions();
});
