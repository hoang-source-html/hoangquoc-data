from pathlib import Path
p=Path('dashboard.js')
s=p.read_text(encoding='utf-8')
s=s.replace("const fields=[['cert',1],['clarity',2],['region',0],['color',4],['range',5]];", "const fields=[['region',0],['plant',21],['cert',1],['color',4],['clarity',2],['range',5]];\nconst priceOptions=[['Price_WH',22],['Price_PO',8],['Price_PO_10%',9],['Price_RAP',10],['Price_RAP_10%',11],['Price_avr_Global',12],['Price_best_Global',13]];\nlet priceIndex=11;")
s=s.replace('pc:Array(6).fill(0),rates:', 'pc:Array(6).fill(0),wh:0,whc:0,noPrice:0,rates:')
start=s.index('function add(a,r)')
end=s.index('function key(',start)
s=s[:start]+'''function add(a,r){a.n++;a.stock+=r[6]??0;a.carat+=r[7]??0;if(r[22]!==null){a.wh+=r[22];a.whc++}for(let i=0;i<6;i++){if(r[8+i]!==null){a.prices[i]+=r[8+i];a.pc[i]++}if(r[14+i]!==null&&r[priceIndex]!==null){a.rates[i]+=r[14+i]*r[priceIndex];a.rc[i]++}}if(r[priceIndex]===null)a.noPrice++;if(r[20]?.startsWith('Chưa có khóa'))a.missing++;else if(r[20])a.incomplete++}
'''+s[end:]
start=s.index('function avg(')
end=s.index('function nodeRow(',start)
s=s[:start]+'''function final(a){return a.n&&a.rc.every(n=>n>0)?a.rates.reduce((sum,v)=>sum+v,0):null}
function nullCell(title){return '<span class="null" title="'+esc(title)+'">—</span>'}
function warning(a,count){return count<a.n?'<span class="warn-dot" aria-label="Tổng chưa đầy đủ" title="'+count+'/'+a.n+' dòng đã tính"></span>':''}
function cells(a){let out='<td>'+fmt(a.carat,3)+'</td><td>'+fmt(a.stock)+'</td><td title="'+a.whc+'/'+a.n+' dòng có giá">'+(a.whc?fmt(a.wh,2)+warning(a,a.whc):nullCell('Thiếu Price_WH'))+'</td>';for(let i=0;i<6;i++)out+='<td title="'+a.pc[i]+'/'+a.n+' dòng có giá">'+(a.pc[i]?fmt(a.prices[i],2)+warning(a,a.pc[i]):nullCell('Không có giá trị giá'))+'</td>';for(let i=0;i<6;i++)out+='<td class="rate" title="'+a.rc[i]+'/'+a.n+' dòng đã tính theo '+esc($('price-basis').value)+'">'+(a.rc[i]?fmt(a.rates[i],2)+warning(a,a.rc[i]):nullCell('Thiếu khóa, tỷ lệ hoặc Price'))+'</td>';const f=final(a);return out+'<td class="final">'+(f===null?nullCell('Chưa đủ giá trị cho cả 6 cấp'):fmt(f,2)+warning(a,Math.min(...a.rc)))+'</td>'}
'''+s[end:]
s=s.replace('n.a.missing+n.a.incomplete','n.a.missing+n.a.incomplete+n.a.noPrice')
s=s.replace('colspan="16"','colspan="17"')
start=s.index("$('stock').textContent=")
end=s.index("$('match-count').textContent=",start)
s=s[:start]+'''$('stock').textContent=fmt(currentTotal.stock);$('carat').textContent=fmt(currentTotal.carat,3);for(const[id,value,count]of [['wh',currentTotal.wh,currentTotal.whc],['po',currentTotal.prices[0],currentTotal.pc[0]],['avr',currentTotal.prices[4],currentTotal.pc[4]],['best',currentTotal.prices[5],currentTotal.pc[5]]]){const element=$(id);element.textContent=count?fmt(value,0):'—';element.title=count+'/'+currentTotal.n+' dòng có giá trị; USD';if(count<currentTotal.n&&count>0){const mark=document.createElement('span');mark.className='warn-dot';mark.setAttribute('aria-label','Tổng chưa đầy đủ');element.append(mark)}}$('basis-label').textContent=$('price-basis').value;'''+s[end:]
s=s.replace("$('only-issues').addEventListener('change',apply);", "$('only-issues').addEventListener('change',apply);$('price-basis').addEventListener('change',()=>{priceIndex=priceOptions.find(([name])=>name===$('price-basis').value)[1];apply()});")
s=s.replace("(!$('only-issues').checked||r[20])","(!$('only-issues').checked||r[20]||r[priceIndex]===null)")
s=s.replace('let missing=0,incomplete=0;', 'let missing=0,incomplete=0,noPrice=filtered.filter(r=>r[priceIndex]===null).length;')
s=s.replace("+' dòng có khóa nhưng thiếu tỷ lệ. Phạm vi", "+' dòng có khóa nhưng thiếu tỷ lệ; '+fmt(noPrice)+' dòng thiếu '+$('price-basis').value+'. Phạm vi")
s=s.replace("'Size (mm)','Carat','Số lượng','Price_PO (USD)'", "'Size (mm)','Carat','Số lượng','Price_WH (USD)','Price_PO (USD)'")
s=s.replace("'Không đổi (%)','Rớt 1 cấp (%)','Rớt 2 cấp (%)','Rớt 3 cấp (%)','Rớt 4 cấp (%)','Rớt 5 cấp (%)','Final (%)'", "'Không đổi (USD)','Rớt 1 cấp (USD)','Rớt 2 cấp (USD)','Rớt 3 cấp (USD)','Rớt 4 cấp (USD)','Rớt 5 cấp (USD)','Final (USD)'")
s=s.replace("'Số dòng thiếu tỷ lệ','Ghi chú'", "'Số dòng thiếu tỷ lệ','Số dòng thiếu Price','Price áp dụng','Ghi chú'")
start=s.index('function row(labels,a)')
end=s.index('for(const c of tree)',start)
s=s[:start]+'''function row(labels,a){return[...labels,a.carat,a.stock,a.whc?a.wh:'',...a.prices.map((v,i)=>a.pc[i]?v:''),...a.rates.map((v,i)=>a.rc[i]?v:''),final(a)===null?'':final(a),a.missing,a.incomplete,a.noPrice,$('price-basis').value,'KCS × (1 − Value) × Price; tổng các dòng đã tính'+(a.rc.some(n=>n<a.n)?'; tổng chưa đầy đủ':'')]}'''+s[end:]
s=s.replace('apply();\n', '''function setTheme(theme){document.documentElement.dataset.theme=theme;$('theme-light').setAttribute('aria-pressed',String(theme==='light'));$('theme-dark').setAttribute('aria-pressed',String(theme==='dark'));try{localStorage.setItem('kcr-theme',theme)}catch{}}
$('theme-light').addEventListener('click',()=>setTheme('light'));$('theme-dark').addEventListener('click',()=>setTheme('dark'));
let initialTheme=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';try{const stored=localStorage.getItem('kcr-theme');if(['light','dark'].includes(stored))initialTheme=stored}catch{}setTheme(initialTheme);
apply();
'''.replace('\n+','\n'))
p.write_text(s,encoding='utf-8')
print('Dashboard logic updated.')
