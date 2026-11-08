"""Update the local preview design; source data and Supabase are unchanged."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent
p = root / 'dashboard.template.html'
s = p.read_text(encoding='utf-8')
start = s.index(' <section class="heading"')
end = s.index(' <section class="filter-panel"', start)
labels = [('stock','Số lượng tồn kho','Tổng Stock','i-box'),('carat','Tổng trọng lượng','Carat · ct','i-diamond'),('wh','Giá trị tồn kho','Tổng Price_WH · USD','i-money'),('po','Giá trị theo PO','Tổng Price_PO · USD','i-money'),('avr','Giá trị RAP_Avr','Tổng Price_avr_Global · USD','i-money'),('best','Giá trị RAP_Best','Tổng Price_best_Global · USD','i-money')]
stats = ' <h1 class="sr-only">Báo cáo tồn kho kim cương</h1>\n<section class="stats" aria-label="Chỉ số theo bộ lọc">'
for id,label,hint,icon in labels:
    stats += f'<div class="stat"><div class="stat-label">{label}<svg fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><use href="#{icon}"/></svg></div><div class="stat-number" id="{id}">—</div><div class="stat-hint">{hint}</div></div>'
stats += '</section>\n'
s = s[:start] + stats + s[end:]
start = s.index(' <div class="filters">')
end = s.index('\n <section class="report"',start)
fields=[('region','Region_HS','Tất cả khu vực'),('plant','Plant','Tất cả Plant'),('cert','Loại kiểm định','Tất cả giấy chứng nhận'),('color','Color · Màu sắc','Tất cả màu sắc'),('clarity','Clarity · Độ tinh khiết','Tất cả độ tinh khiết'),('range','Khung carat','Tất cả khoảng carat')]
filters='<div class="filter-heading"><h2>Bộ lọc dữ liệu</h2><button class="text-button" id="reset">Đặt lại bộ lọc</button></div><div class="filters">'
for id,label,placeholder in fields:
    filters += f'<div class="field"><label for="{id}">{label}</label><select id="{id}"><option value="">{placeholder}</option></select></div>'
filters += '</div><div class="filter-bottom"><span><strong id="match-count">—</strong> dòng dữ liệu phù hợp <span id="scope"></span></span><div class="filter-tools"><div class="field search-field"><label class="sr-only" for="search">Tìm trong báo cáo</label><input type="search" id="search" placeholder="Tìm chứng nhận, độ tinh khiết, size…" autocomplete="off"></div><label><input type="checkbox" id="only-issues">Chỉ dòng cần bổ sung Rule</label><button class="text-button" id="issues">Chi tiết Rule thiếu</button></div></div></section>'
s=s[:start]+filters+s[end:]
start=s.index('<div class="report-header">')
end=s.index(' <div class="table-wrap"',start)
header='''<div class="report-header"><div><h2 id="report-title">Chi tiết tồn kho & giá trị theo cấp chất lượng</h2><p>Chứng nhận <span aria-hidden="true">›</span> Độ tinh khiết <span aria-hidden="true">›</span> Size (mm)</p></div><div class="report-controls"><div class="price-field"><label for="price-basis">Price áp dụng cho 6 cấp</label><select id="price-basis">'''
for name in ['Price_WH','Price_PO','Price_PO_10%','Price_RAP','Price_RAP_10%','Price_avr_Global','Price_best_Global']:
    selected=' selected' if name=='Price_RAP_10%' else ''
    header+=f'<option{selected}>{name}</option>'
header+='''</select></div><button class="button" id="method">Cách tính</button><button class="button primary" id="export" aria-label="Xuất CSV"><svg fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><use href="#i-download"/></svg>Xuất CSV</button></div></div><div class="report-subbar"><div class="formula-chip">Giá trị cấp = tỷ lệ KCS × (1 − tỷ lệ Value) × <strong id="basis-label">Price_RAP_10%</strong></div><div class="table-actions"><button class="button" id="expand">Mở tất cả</button><button class="button" id="collapse">Thu gọn</button></div></div><div class="rate-notice">Đơn vị USD · Tính từng dòng, sau đó cộng theo nhóm. Dấu <span class="warn-dot"></span> kèm ghi chú: tổng đang thiếu dòng chưa đủ Rule hoặc Price. Không quy giá trị thiếu thành 0.</div>\n'''
s=s[:start]+header+s[end:]
s=s.replace('colspan="6" scope="colgroup">Giá trị tham chiếu','colspan="7" scope="colgroup">Giá trị tham chiếu')
s=s.replace('Tỷ lệ theo Rule (%)','Giá trị theo cấp chất lượng (USD)')
s=s.replace('<th scope="col">Price_PO</th>','<th scope="col">Price_WH</th><th scope="col">Price_PO</th>')
s=s.replace('cuộn ngang để xem các cột tỷ lệ','cuộn ngang để xem các cột giá trị')
s=s.replace('giá trị USD và tỷ lệ phần trăm.','các giá trị tiền tệ theo USD.')
s=s.replace('đầy đủ 16 cột','đầy đủ 17 cột')
start=s.index('<div class="note-box"><strong>Tại từng dòng:</strong>')
end=s.index('<details>',start)
s=s[:start]+'''<div class="note-box"><strong>Tại từng dòng, mỗi cấp:</strong><br>Rule_kcs[Key_KCS, cấp] × (1 − Rule_value[Key_Value, cấp]) × Price được chọn.<br>Key_KCS = Chứng nhận * Độ tinh khiết.<br>Key_Value = Khoảng carat * Độ tinh khiết * Màu.<br><strong>Mặc định:</strong> Price_RAP_10%. Tỷ lệ được giữ dưới dạng thập phân khi tính.</div><p><strong>Tại từng nhóm:</strong> cộng các giá trị của từng dòng. Sáu cấp là giá trị USD, hiển thị hai chữ số thập phân. Final = tổng sáu cấp đã tính. Nếu một cấp không tính được ở bất kỳ dòng nào, tổng phần đã tính kèm dấu cảnh báo; nếu cả cấp không có giá trị thì hiển thị “—”. Final chỉ hiển thị nếu cả sáu cấp có giá trị; kèm cảnh báo khi còn dòng thiếu. Không làm tròn trước khi cộng.</p><p><strong>KPI:</strong> cộng Stock, Carat, Price_WH, Price_PO, Price_avr_Global và Price_best_Global theo bộ lọc. Không đổi KPI khi chọn Price cho sáu cấp; không nhân lại với Stock.</p><p>Khóa không tìm thấy: “Chưa có khóa”. Ô Rule trống: “Thiếu tỷ lệ trong Rule”. Price trống: “Thiếu Price”. Không thay dữ liệu thiếu bằng 0.</p>'''+s[end:]
s=s.replace('<div class="top-right"><span>KCR Workspace</span>', '<div class="top-right"><div class="theme-switch" role="group" aria-label="Giao diện"><button id="theme-light" aria-pressed="true">Sáng</button><button id="theme-dark" aria-pressed="false">Tối</button></div>')
start=s.index("'use strict';")
end=s.index('</script>',start)
s=s[:start]+(root/'dashboard.js').read_text(encoding='utf-8')+'\n'+s[end:]
s=s.replace('</style>',(root/'dashboard-theme.css').read_text(encoding='utf-8')+'\n</style>')
p.write_text(s,encoding='utf-8')
print('Dashboard template updated.')
