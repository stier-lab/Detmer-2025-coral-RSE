import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = '/Users/adrianstier/Detmer-2025-coral-RSE/model-diagram/test-results';
fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

const results = [];
function log(test, status, detail = '') {
  const entry = { test, status, detail };
  results.push(entry);
  console.log(`[${status}] ${test}${detail ? ' -- ' + detail : ''}`);
}

async function screenshot(page, name) {
  const filePath = path.join(SCREENSHOT_DIR, `${name}.png`);
  await page.screenshot({ path: filePath, fullPage: true });
  return filePath;
}

// Helper: get bounding box center of an element via evaluate
async function getCenter(page, selector) {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2, width: rect.width, height: rect.height };
  }, selector);
}

// Helper: wait for D3 transitions to settle
async function waitForTransitions(page) {
  await page.waitForTimeout(600);
}

// Helper: dispatch click event on SVG element via JS
async function svgClick(page, selector) {
  const center = await getCenter(page, selector);
  if (!center) return false;
  await page.mouse.click(center.x, center.y);
  return true;
}

// Helper: dispatch mouse hover on SVG element via coordinates
async function svgHover(page, selector) {
  const center = await getCenter(page, selector);
  if (!center) return false;
  await page.mouse.move(center.x, center.y);
  return true;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1400, height: 1000 } });
  const page = await context.newPage();

  // Collect console errors
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', err => {
    consoleErrors.push(err.message);
  });

  await page.goto('http://localhost:5173', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500); // Let D3 render fully

  await screenshot(page, '00-initial-state');

  // ===============================================================
  // TEST 1: Expand/collapse each location individually
  // ===============================================================
  console.log('\n=== TEST 1: Expand/Collapse Each Location ===');

  for (const locId of ['lab', 'orchard', 'reef']) {
    // --- EXPAND ---
    // Use the location-bg rect to get position; click directly via mouse coordinates
    const bgRect = await page.evaluate((id) => {
      const el = document.querySelector(`.location-${id} .location-bg`);
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
    }, locId);

    if (!bgRect) {
      log(`1a-expand-${locId}`, 'FAIL', `Could not find .location-${locId} .location-bg`);
      continue;
    }

    // Click to expand using D3 dispatch since mouse.click on SVG can be flaky
    await page.evaluate((id) => {
      const el = document.querySelector(`.location-${id}`);
      if (el) {
        const event = new MouseEvent('click', { bubbles: true, cancelable: true });
        el.dispatchEvent(event);
      }
    }, locId);
    await waitForTransitions(page);

    // Check expansion
    const expandedHeight = await page.evaluate((id) => {
      const bg = document.querySelector(`.location-${id} .location-bg`);
      return bg ? parseFloat(bg.getAttribute('height')) : null;
    }, locId);

    const detailExpanded = await page.evaluate((id) => {
      const detail = document.querySelector(`.location-detail[data-location="${id}"]`);
      return detail ? detail.classList.contains('expanded') : false;
    }, locId);

    const hintTextExpanded = await page.evaluate((id) => {
      const hint = document.querySelector(`.location-${id} .click-hint`);
      return hint ? hint.textContent : null;
    }, locId);

    if (expandedHeight === 420 && detailExpanded && hintTextExpanded === 'click to collapse') {
      log(`1a-expand-${locId}`, 'PASS', `height=${expandedHeight}, detail.expanded=${detailExpanded}, hint="${hintTextExpanded}"`);
    } else {
      log(`1a-expand-${locId}`, 'FAIL', `height=${expandedHeight} (expect 420), detail.expanded=${detailExpanded}, hint="${hintTextExpanded}" (expect "click to collapse")`);
    }

    await screenshot(page, `01-expanded-${locId}`);

    // --- COLLAPSE ---
    await page.evaluate((id) => {
      const el = document.querySelector(`.location-${id}`);
      if (el) {
        const event = new MouseEvent('click', { bubbles: true, cancelable: true });
        el.dispatchEvent(event);
      }
    }, locId);
    await waitForTransitions(page);

    const collapsedHeight = await page.evaluate((id) => {
      const bg = document.querySelector(`.location-${id} .location-bg`);
      return bg ? parseFloat(bg.getAttribute('height')) : null;
    }, locId);

    const detailCollapsed = await page.evaluate((id) => {
      const detail = document.querySelector(`.location-detail[data-location="${id}"]`);
      return detail ? !detail.classList.contains('expanded') : false;
    }, locId);

    const hintTextCollapsed = await page.evaluate((id) => {
      const hint = document.querySelector(`.location-${id} .click-hint`);
      return hint ? hint.textContent : null;
    }, locId);

    if (collapsedHeight === 80 && detailCollapsed && hintTextCollapsed === 'click to expand') {
      log(`1b-collapse-${locId}`, 'PASS', `height=${collapsedHeight}, hint="${hintTextCollapsed}"`);
    } else {
      log(`1b-collapse-${locId}`, 'FAIL', `height=${collapsedHeight} (expect 80), detail.collapsed=${detailCollapsed}, hint="${hintTextCollapsed}" (expect "click to expand")`);
    }
  }

  // ===============================================================
  // TEST 2: Expand All / Collapse All buttons
  // ===============================================================
  console.log('\n=== TEST 2: Expand All / Collapse All ===');

  await page.click('#expand-all');
  await waitForTransitions(page);

  const allExpandedHeights = await page.evaluate(() => {
    return ['lab', 'orchard', 'reef'].map(id => {
      const bg = document.querySelector(`.location-${id} .location-bg`);
      return { id, height: bg ? parseFloat(bg.getAttribute('height')) : null };
    });
  });

  const allExpanded = allExpandedHeights.every(h => h.height === 420);
  const allDetailsExpanded = await page.evaluate(() => {
    return ['lab', 'orchard', 'reef'].every(id => {
      const d = document.querySelector(`.location-detail[data-location="${id}"]`);
      return d && d.classList.contains('expanded');
    });
  });

  if (allExpanded && allDetailsExpanded) {
    log('2a-expand-all', 'PASS', `All heights: ${allExpandedHeights.map(h => h.height).join(', ')}`);
  } else {
    log('2a-expand-all', 'FAIL', `Heights: ${JSON.stringify(allExpandedHeights)}, allDetailsExpanded=${allDetailsExpanded}`);
  }

  await screenshot(page, '02-expand-all');

  await page.click('#collapse-all');
  await waitForTransitions(page);

  const allCollapsedHeights = await page.evaluate(() => {
    return ['lab', 'orchard', 'reef'].map(id => {
      const bg = document.querySelector(`.location-${id} .location-bg`);
      return { id, height: bg ? parseFloat(bg.getAttribute('height')) : null };
    });
  });

  const allCollapsed = allCollapsedHeights.every(h => h.height === 80);
  const allDetailsCollapsed = await page.evaluate(() => {
    return ['lab', 'orchard', 'reef'].every(id => {
      const d = document.querySelector(`.location-detail[data-location="${id}"]`);
      return d && !d.classList.contains('expanded');
    });
  });

  if (allCollapsed && allDetailsCollapsed) {
    log('2b-collapse-all', 'PASS', `All heights: ${allCollapsedHeights.map(h => h.height).join(', ')}`);
  } else {
    log('2b-collapse-all', 'FAIL', `Heights: ${JSON.stringify(allCollapsedHeights)}, allDetailsCollapsed=${allDetailsCollapsed}`);
  }

  await screenshot(page, '02-collapse-all');

  // ===============================================================
  // TEST 3: Tooltip on hover
  // ===============================================================
  console.log('\n=== TEST 3: Tooltip on Hover ===');

  async function checkTooltipViaDispatch(page, selector, testName) {
    // Move mouse away and reset tooltip
    await page.mouse.move(10, 10);
    await page.waitForTimeout(300);

    // Dispatch mouseenter event on the SVG element
    const found = await page.evaluate((sel) => {
      const el = document.querySelector(sel);
      if (!el) return false;
      const rect = el.getBoundingClientRect();
      const event = new MouseEvent('mouseenter', {
        bubbles: true,
        cancelable: true,
        clientX: rect.x + rect.width / 2,
        clientY: rect.y + rect.height / 2,
      });
      el.dispatchEvent(event);
      return true;
    }, selector);

    if (!found) {
      log(testName, 'FAIL', `Element not found: ${selector}`);
      return;
    }

    await page.waitForTimeout(200);

    const tooltipState = await page.evaluate(() => {
      const tt = document.getElementById('tooltip');
      const title = tt.querySelector('.tooltip-title');
      const body = tt.querySelector('.tooltip-body');
      return {
        hidden: tt.classList.contains('hidden'),
        title: title ? title.textContent : '',
        bodyLength: body ? body.textContent.length : 0,
      };
    });

    if (!tooltipState.hidden && tooltipState.title.length > 0 && tooltipState.bodyLength > 0) {
      log(testName, 'PASS', `title="${tooltipState.title.substring(0, 60)}...", bodyLen=${tooltipState.bodyLength}`);
    } else {
      log(testName, 'FAIL', `hidden=${tooltipState.hidden}, title="${tooltipState.title}", bodyLen=${tooltipState.bodyLength}`);
    }

    // Dispatch mouseleave to hide
    await page.evaluate((sel) => {
      const el = document.querySelector(sel);
      if (el) {
        const event = new MouseEvent('mouseleave', { bubbles: true, cancelable: true });
        el.dispatchEvent(event);
      }
    }, selector);
    await page.waitForTimeout(200);
  }

  // 3a: Location box tooltips
  await checkTooltipViaDispatch(page, '.location-lab', '3a-tooltip-location-lab');
  await checkTooltipViaDispatch(page, '.location-orchard', '3a-tooltip-location-orchard');
  await checkTooltipViaDispatch(page, '.location-reef', '3a-tooltip-location-reef');

  // 3b: Flow arrow tooltip
  await checkTooltipViaDispatch(page, '.flow-group', '3b-tooltip-flow-arrow');

  // 3c: Decision diamond tooltip
  await checkTooltipViaDispatch(page, '.decision-diamond', '3c-tooltip-decision-diamond');

  // 3d: External input tooltip
  await checkTooltipViaDispatch(page, '.external-input', '3d-tooltip-external-input');

  // 3e: Equation badge tooltip
  await checkTooltipViaDispatch(page, '.equation-group', '3e-tooltip-equation-badge');

  await screenshot(page, '03-tooltips-done');

  // ===============================================================
  // TEST 4: Tooltip hides on click
  // ===============================================================
  console.log('\n=== TEST 4: Tooltip Hides on Click ===');

  // Show tooltip on lab via mouseenter
  await page.evaluate(() => {
    const el = document.querySelector('.location-lab');
    const rect = el.getBoundingClientRect();
    el.dispatchEvent(new MouseEvent('mouseenter', {
      bubbles: true, cancelable: true,
      clientX: rect.x + rect.width / 2,
      clientY: rect.y + rect.height / 2,
    }));
  });
  await page.waitForTimeout(300);

  const tooltipVisibleBeforeClick = await page.evaluate(() => {
    return !document.getElementById('tooltip').classList.contains('hidden');
  });

  // Click the location (which should call hideTooltip + toggle)
  await page.evaluate(() => {
    const el = document.querySelector('.location-lab');
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  });
  await page.waitForTimeout(200);

  const tooltipHiddenAfterClick = await page.evaluate(() => {
    return document.getElementById('tooltip').classList.contains('hidden');
  });

  if (tooltipVisibleBeforeClick && tooltipHiddenAfterClick) {
    log('4-tooltip-hides-on-click', 'PASS', `visibleBefore=${tooltipVisibleBeforeClick}, hiddenAfter=${tooltipHiddenAfterClick}`);
  } else {
    log('4-tooltip-hides-on-click', 'FAIL', `visibleBefore=${tooltipVisibleBeforeClick}, hiddenAfter=${tooltipHiddenAfterClick}`);
  }

  await screenshot(page, '04-tooltip-click');

  // Collapse lab back
  await page.evaluate(() => {
    const el = document.querySelector('.location-lab');
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  });
  await waitForTransitions(page);

  // ===============================================================
  // TEST 5: Pathway highlighting
  // ===============================================================
  console.log('\n=== TEST 5: Pathway Highlighting ===');

  const pathways = [
    { value: 'wild', name: 'Wild recruits', expectedDimmedLocs: ['lab', 'orchard'] },
    { value: '0tx', name: '0_TX', expectedDimmedLocs: [] },
    { value: '1tx', name: '1_TX', expectedDimmedLocs: [] },
    { value: 'transplant', name: 'Transplant', expectedDimmedLocs: ['lab'] },
  ];

  for (const pw of pathways) {
    await page.selectOption('#pathway-select', pw.value);
    await page.waitForTimeout(300);

    const locDimState = await page.evaluate(() => {
      return ['lab', 'orchard', 'reef'].map(id => {
        const el = document.querySelector(`.location-${id}`);
        return { id, dimmed: el ? el.classList.contains('dimmed') : null };
      });
    });

    const flowStates = await page.evaluate(() => {
      const flows = document.querySelectorAll('.flow-group');
      return Array.from(flows).map(f => ({
        id: f.getAttribute('data-flow'),
        dimmed: f.classList.contains('dimmed'),
        highlighted: f.classList.contains('highlighted'),
        pathways: f.getAttribute('data-pathways'),
      }));
    });

    // Check decision diamonds too
    const decisionStates = await page.evaluate(() => {
      const decs = document.querySelectorAll('.decision-diamond');
      return Array.from(decs).map(d => ({
        id: d.getAttribute('data-decision'),
        dimmed: d.classList.contains('dimmed'),
        highlighted: d.classList.contains('highlighted'),
        pathways: d.getAttribute('data-pathways'),
      }));
    });

    // Check external inputs
    const externalStates = await page.evaluate(() => {
      const exts = document.querySelectorAll('.external-input');
      return Array.from(exts).map(e => ({
        id: e.getAttribute('data-external'),
        dimmed: e.classList.contains('dimmed'),
        highlighted: e.classList.contains('highlighted'),
        pathways: e.getAttribute('data-pathways'),
      }));
    });

    // Verify location dimming
    let locCorrect = true;
    for (const loc of locDimState) {
      const shouldBeDimmed = pw.expectedDimmedLocs.includes(loc.id);
      if (loc.dimmed !== shouldBeDimmed) locCorrect = false;
    }

    // Verify flow highlighting
    let flowCorrect = true;
    for (const flow of flowStates) {
      const flowPathways = flow.pathways.split(',');
      const shouldHighlight = flowPathways.includes(pw.value);
      if (flow.highlighted !== shouldHighlight || flow.dimmed !== !shouldHighlight) flowCorrect = false;
    }

    // Verify decision highlighting
    let decCorrect = true;
    for (const dec of decisionStates) {
      const decPathways = dec.pathways.split(',');
      const shouldHighlight = decPathways.includes(pw.value);
      if (dec.highlighted !== shouldHighlight || dec.dimmed !== !shouldHighlight) decCorrect = false;
    }

    // Verify external highlighting
    let extCorrect = true;
    for (const ext of externalStates) {
      const extPathways = ext.pathways.split(',');
      const shouldHighlight = extPathways.includes(pw.value);
      if (ext.highlighted !== shouldHighlight || ext.dimmed !== !shouldHighlight) extCorrect = false;
    }

    const details = [];
    if (!locCorrect) details.push(`LOC: ${JSON.stringify(locDimState)}`);
    if (!flowCorrect) details.push(`FLOW: ${JSON.stringify(flowStates)}`);
    if (!decCorrect) details.push(`DEC: ${JSON.stringify(decisionStates)}`);
    if (!extCorrect) details.push(`EXT: ${JSON.stringify(externalStates)}`);

    if (locCorrect && flowCorrect && decCorrect && extCorrect) {
      log(`5a-pathway-${pw.value}`, 'PASS', `All elements correctly highlighted/dimmed`);
    } else {
      log(`5a-pathway-${pw.value}`, 'FAIL', details.join('; '));
    }

    await screenshot(page, `05-pathway-${pw.value}`);
  }

  // Reset to all pathways
  await page.selectOption('#pathway-select', '');
  await page.waitForTimeout(300);

  const resetState = await page.evaluate(() => {
    const dimmed = document.querySelectorAll('.dimmed');
    const highlighted = document.querySelectorAll('.highlighted');
    return { dimmedCount: dimmed.length, highlightedCount: highlighted.length };
  });

  if (resetState.dimmedCount === 0 && resetState.highlightedCount === 0) {
    log('5b-pathway-reset', 'PASS', 'All dimmed/highlighted classes removed');
  } else {
    log('5b-pathway-reset', 'FAIL', `dimmedCount=${resetState.dimmedCount}, highlightedCount=${resetState.highlightedCount}`);
  }

  await screenshot(page, '05-pathway-reset');

  // ===============================================================
  // TEST 6: Layer toggles
  // ===============================================================
  console.log('\n=== TEST 6: Layer Toggles ===');

  const layers = ['disturbance', 'stochasticity', 'costs', 'density'];

  for (const layer of layers) {
    // Check layer off by default
    const svgHasClassBefore = await page.evaluate((l) => {
      return document.getElementById('diagram').classList.contains(`show-${l}`);
    }, layer);

    // Toggle on by clicking the label (pill), not the hidden input
    await page.click(`.toggle-pill[data-color="${layer}"]`);
    await page.waitForTimeout(300);

    const svgHasClassAfter = await page.evaluate((l) => {
      return document.getElementById('diagram').classList.contains(`show-${l}`);
    }, layer);

    // Check the checkbox is now checked
    const isChecked = await page.evaluate((l) => {
      const input = document.querySelector(`input[data-layer="${l}"]`);
      return input ? input.checked : null;
    }, layer);

    // Check that layer elements are now visible
    const layerVisible = await page.evaluate((l) => {
      const els = document.querySelectorAll(`.layer-${l}`);
      if (els.length === 0) return { count: 0, anyVisible: false };
      let anyVisible = false;
      els.forEach(el => {
        const style = window.getComputedStyle(el);
        if (style.display !== 'none') anyVisible = true;
      });
      return { count: els.length, anyVisible };
    }, layer);

    if (!svgHasClassBefore && svgHasClassAfter && layerVisible.anyVisible && isChecked) {
      log(`6a-layer-on-${layer}`, 'PASS', `class added, ${layerVisible.count} element(s) visible, checkbox checked`);
    } else {
      log(`6a-layer-on-${layer}`, 'FAIL', `classBefore=${svgHasClassBefore}, classAfter=${svgHasClassAfter}, checked=${isChecked}, visible=${JSON.stringify(layerVisible)}`);
    }

    await screenshot(page, `06-layer-${layer}-on`);

    // Toggle off
    await page.click(`.toggle-pill[data-color="${layer}"]`);
    await page.waitForTimeout(300);

    const svgHasClassOff = await page.evaluate((l) => {
      return document.getElementById('diagram').classList.contains(`show-${l}`);
    }, layer);

    const layerHidden = await page.evaluate((l) => {
      const els = document.querySelectorAll(`.layer-${l}`);
      let allHidden = true;
      els.forEach(el => {
        const style = window.getComputedStyle(el);
        if (style.display !== 'none') allHidden = false;
      });
      return allHidden;
    }, layer);

    const isUnchecked = await page.evaluate((l) => {
      const input = document.querySelector(`input[data-layer="${l}"]`);
      return input ? !input.checked : null;
    }, layer);

    if (!svgHasClassOff && layerHidden && isUnchecked) {
      log(`6b-layer-off-${layer}`, 'PASS', 'class removed, elements hidden, checkbox unchecked');
    } else {
      log(`6b-layer-off-${layer}`, 'FAIL', `classStillOn=${svgHasClassOff}, allHidden=${layerHidden}, unchecked=${isUnchecked}`);
    }
  }

  await screenshot(page, '06-layers-done');

  // ===============================================================
  // TEST 7: Size class click stops propagation
  // ===============================================================
  console.log('\n=== TEST 7: Size Class Click Stops Propagation ===');

  // Expand reef first
  await page.evaluate(() => {
    const el = document.querySelector('.location-reef');
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  });
  await waitForTransitions(page);

  const reefExpandedBefore = await page.evaluate(() => {
    const detail = document.querySelector('.location-detail[data-location="reef"]');
    return detail && detail.classList.contains('expanded');
  });

  if (!reefExpandedBefore) {
    log('7-sc-click-propagation', 'FAIL', 'Could not expand reef for test');
  } else {
    // Click on a size class node inside reef
    const scClicked = await page.evaluate(() => {
      const scNode = document.querySelector('.location-reef .sc-node');
      if (!scNode) return false;
      scNode.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
      return true;
    });

    await waitForTransitions(page);

    if (!scClicked) {
      log('7-sc-click-propagation', 'FAIL', 'No sc-node found inside expanded reef');
    } else {
      const reefExpandedAfter = await page.evaluate(() => {
        const detail = document.querySelector('.location-detail[data-location="reef"]');
        return detail && detail.classList.contains('expanded');
      });

      if (reefExpandedAfter) {
        log('7-sc-click-propagation', 'PASS', 'Reef stayed expanded after clicking size class node');
      } else {
        log('7-sc-click-propagation', 'FAIL', 'Reef collapsed when clicking size class node -- stopPropagation not working');
      }
    }
  }

  await screenshot(page, '07-sc-click');

  // Also test with orchard (which also has size classes)
  await page.evaluate(() => {
    const el = document.querySelector('.location-orchard');
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  });
  await waitForTransitions(page);

  const orchExpandedBefore = await page.evaluate(() => {
    const detail = document.querySelector('.location-detail[data-location="orchard"]');
    return detail && detail.classList.contains('expanded');
  });

  if (orchExpandedBefore) {
    const scClicked2 = await page.evaluate(() => {
      const scNode = document.querySelector('.location-orchard .sc-node');
      if (!scNode) return false;
      scNode.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
      return true;
    });
    await waitForTransitions(page);

    if (scClicked2) {
      const orchExpandedAfter = await page.evaluate(() => {
        const detail = document.querySelector('.location-detail[data-location="orchard"]');
        return detail && detail.classList.contains('expanded');
      });
      if (orchExpandedAfter) {
        log('7b-sc-click-orchard', 'PASS', 'Orchard stayed expanded after clicking size class node');
      } else {
        log('7b-sc-click-orchard', 'FAIL', 'Orchard collapsed when clicking size class node');
      }
    }
  }

  // Collapse all
  await page.click('#collapse-all');
  await waitForTransitions(page);

  // ===============================================================
  // TEST: Size class tooltip (expanded state)
  // ===============================================================
  console.log('\n=== BONUS: Size Class Tooltip ===');

  await page.click('#expand-all');
  await waitForTransitions(page);

  await page.evaluate(() => {
    const el = document.querySelector('.location-reef .sc-node');
    if (!el) return;
    const rect = el.getBoundingClientRect();
    el.dispatchEvent(new MouseEvent('mouseenter', {
      bubbles: true, cancelable: true,
      clientX: rect.x + rect.width / 2,
      clientY: rect.y + rect.height / 2,
    }));
  });
  await page.waitForTimeout(300);

  const scTooltip = await page.evaluate(() => {
    const tt = document.getElementById('tooltip');
    return {
      hidden: tt.classList.contains('hidden'),
      title: tt.querySelector('.tooltip-title').textContent,
      bodyLen: tt.querySelector('.tooltip-body').textContent.length,
    };
  });

  if (!scTooltip.hidden && scTooltip.title.length > 0) {
    log('bonus-sc-tooltip', 'PASS', `title="${scTooltip.title}"`);
  } else {
    log('bonus-sc-tooltip', 'FAIL', `hidden=${scTooltip.hidden}, title="${scTooltip.title}"`);
  }

  await page.click('#collapse-all');
  await waitForTransitions(page);

  // ===============================================================
  // TEST 8: Console errors
  // ===============================================================
  console.log('\n=== TEST 8: Console Errors ===');

  if (consoleErrors.length === 0) {
    log('8-console-errors', 'PASS', 'No JavaScript console errors detected');
  } else {
    log('8-console-errors', 'FAIL', `${consoleErrors.length} error(s): ${consoleErrors.join(' | ')}`);
  }

  await screenshot(page, '99-final-state');

  // ===============================================================
  // SUMMARY
  // ===============================================================
  console.log('\n' + '='.repeat(60));
  console.log('TEST RESULTS SUMMARY');
  console.log('='.repeat(60));

  const passed = results.filter(r => r.status === 'PASS').length;
  const failed = results.filter(r => r.status === 'FAIL').length;
  const total = results.length;

  console.log(`\nTotal: ${total}  |  PASS: ${passed}  |  FAIL: ${failed}\n`);

  for (const r of results) {
    const icon = r.status === 'PASS' ? 'OK' : 'XX';
    console.log(`  [${icon}] ${r.test}${r.detail ? '\n      ' + r.detail : ''}`);
  }

  if (failed > 0) {
    console.log(`\n>>> ${failed} test(s) FAILED -- see details above <<<`);
  } else {
    console.log('\n>>> ALL TESTS PASSED <<<');
  }

  await browser.close();
})();
