const {chromium}=require('C:/Users/quoc.vh/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('path');const fs=require('fs');const assert=require('assert/strict');const ref=require('./dashboard-expected.json');
(async()=>{
const browser=await chromium.launch({headless:true,channel:'msedge'});
const page=await browser.newPage({viewport:{width:1600,height:1000},deviceScaleFactor:1});
const errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('file:///'+path.join(__dirname,'index.html').replace(/\\/g,'/'));
await page.waitForFunction(()=>document.querySelector('#table-count').textContent.includes('18,729'));
await page.locator('#theme-light').click();
assert.equal(await page.locator('#price-basis').inputValue(),'Price_RAP_10%');
assert.equal(await page.locator('.stats .stat').count(),6);assert.equal(await page.locator('.heading').count(),0);
assert.deepEqual(await page.locator('.filters select').evaluateAll(els=>els.map(e=>e.id)),['region','plant','cert','range','size','color','clarity']);
const tops=await page.locator('.stat').evaluateAll(es=>es.map(e=>e.getBoundingClientRect().top));assert.ok(tops.every(v=>v===tops[0]));
assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
assert.equal(await page.locator('.brand strong').innerText(),'KCR-KCSX');assert.equal(await page.locator('.brand small').innerText(),'có Cert');assert.equal(await page.locator('#page-nav a span').first().innerText(),'Dự kiến xử lý KCS');assert.equal(await page.evaluate(()=>fmt(203208.73,2)),'203,208.73');
await page.locator('#size').selectOption('3.5');assert.ok(await page.evaluate(()=>filtered.length>0&&filtered.every(r=>r[3]===3.5)));await page.locator('#reset').click();
let kpis=await page.locator('.stats').innerText();
const names=['Price_WH','Price_PO','Price_PO_10%','Price_RAP','Price_RAP_10%','Price_avr_Global','Price_best_Global'];const keys=Object.keys(ref.totals);
for(let i=0;i<names.length;i++){
 await page.locator('#price-basis').selectOption(names[i]);
 const values=await page.evaluate(()=>({s:currentTotal.rates,c:currentTotal.rc,k:[currentTotal.wh,currentTotal.prices[0],currentTotal.prices[4],currentTotal.prices[5]]}));
 values.s.forEach((v,j)=>assert.ok(Math.abs(v-ref.totals[keys[i]][j])<0.0001,`${names[i]} level ${j}: ${v}`));
 assert.deepEqual(values.c,ref.counts[keys[i]]);assert.equal(await page.locator('.stats').innerText(),kpis);
 const kpiKeys=['price_wh','price_po','price_avr_global','price_best_global'];values.k.forEach((v,j)=>assert.ok(Math.abs(v-ref.kpi[kpiKeys[j]])<0.0001));
}
await page.locator('#price-basis').selectOption('Price_RAP_10%');
await page.getByRole('button',{name:'Thu gọn',exact:true}).click();const collapsed=await page.locator('#table-body tr').count();
await page.getByRole('button',{name:'Mở tất cả',exact:true}).click();assert.ok(await page.locator('#table-body tr').count()>collapsed);
await page.locator('#plant').selectOption({index:1});assert.ok(await page.evaluate(()=>filtered.length>0));
await page.locator('#reset').click();assert.equal(await page.locator('#search,#only-issues,#issues,.filter-heading,.filter-bottom,.report-subbar,.rate-notice').count(),0);assert.ok(await page.locator('.table-wrap').evaluate(e=>e.getBoundingClientRect().height)>600);await page.screenshot({path:path.join(__dirname,'dashboard-preview.png'),fullPage:true});
await page.locator('#theme-dark').click();assert.equal(await page.locator('html').getAttribute('data-theme'),'dark');
await page.reload();assert.equal(await page.locator('html').getAttribute('data-theme'),'dark');await page.screenshot({path:path.join(__dirname,'dashboard-dark.png'),fullPage:true});
for(const width of [375,768,1024,1440]){await page.setViewportSize({width,height:900});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,`overflow ${width}`)}
await page.setViewportSize({width:375,height:844});await page.locator('#menu-toggle').click();assert.equal(await page.locator('#menu-toggle').getAttribute('aria-expanded'),'true');await page.locator('#shade').click({position:{x:320,y:200}});assert.equal(await page.locator('#menu-toggle').getAttribute('aria-expanded'),'false');
await page.screenshot({path:path.join(__dirname,'dashboard-mobile.png'),fullPage:true});await page.locator('#theme-light').click();await page.screenshot({path:path.join(__dirname,'dashboard-mobile-light.png'),fullPage:true});
const downloadPromise=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadPromise;await download.saveAs(path.join(__dirname,'preview-export-check.csv'));assert.ok(fs.readFileSync(path.join(__dirname,'preview-export-check.csv'),'utf8').includes('Price_RAP_10%'));
assert.deepEqual(errors,[]);console.log('PASS: 7 prices × 6 levels match independent Decimal reference; KPI sums and independence; 6 KPI desktop row; filter order and Plant; removed controls; table height >600px; CSV; themes; responsive 375/768/1024/1440; group toggles; no JS errors.');await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
