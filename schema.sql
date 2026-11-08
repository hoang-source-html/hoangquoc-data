-- KCR / Supabase / PostgreSQL 15+
-- Run this entire file in Supabase SQL Editor, then import data.csv into public.data.
-- Rules are seeded below from Data-Rule.xlsx. The source workbook is unchanged.
-- First-time setup: deliberately fails if these table names already exist.
-- No DROP/TRUNCATE. The transaction rolls back on failure.
-- CSV uses snake_case headers; do not import the original Excel headers directly.
-- All monetary values retain the workbook units (price_*: USD; po_amt/tong_von: VND).
-- Ratios remain fractions: 0.2536 => 25.36%; format at display time, not in storage.
-- Blank rule cells remain NULL, distinct from explicit zero.
-- Missing keys are permitted: no foreign keys from Data to incomplete rule tables.
-- No report aggregation/Final is defined until its aggregation rule is confirmed.
-- Security: browser roles get no data access by default; SQL Editor can import/read.
-- Add a deliberate SELECT RLS policy for approved users before wiring the HTML app.
-- Docs: https://supabase.com/docs/guides/database/postgres/row-level-security
-- Docs: https://supabase.com/docs/guides/database/import-data

begin;

create table public.rule_kcs (
    key_kcs text primary key,
    unchanged numeric check (unchanged between 0 and 1),
    drop_1 numeric check (drop_1 between 0 and 1),
    drop_2 numeric check (drop_2 between 0 and 1),
    drop_3 numeric check (drop_3 between 0 and 1),
    drop_4 numeric check (drop_4 between 0 and 1),
    drop_5 numeric check (drop_5 between 0 and 1)
);

create table public.rule_value (
    key_value text primary key,
    unchanged numeric check (unchanged between 0 and 1),
    drop_1 numeric check (drop_1 between 0 and 1),
    drop_2 numeric check (drop_2 between 0 and 1),
    drop_3 numeric check (drop_3 between 0 and 1),
    drop_4 numeric check (drop_4 between 0 and 1),
    drop_5 numeric check (drop_5 between 0 and 1)
);

create table public.data (
    id bigint generated always as identity primary key,
    region_hs text,
    plant text,
    type text,
    material text,
    batch text,
    range_carat text,
    stock numeric,
    carat numeric,
    dinh_luong_pnj numeric,
    sloc text,
    clarity text,
    color text,
    size numeric,
    cert_type text,
    group_name text,
    filter_x text,
    filter_y text,
    price_wh numeric,
    price_po numeric,
    price_po_10 numeric,
    price_rap numeric,
    price_rap_10 numeric,
    price_avr_global numeric,
    price_best_global numeric,
    rapaport_per_ct numeric,
    global_trade_avg_per_ct numeric,
    global_trade_best_per_ct numeric,
    po_number text,
    po_amt numeric,
    batch_goc text,
    po_date date,
    stock_type text,
    tong_von numeric,
    key_kcs text generated always as
        (coalesce(cert_type, '') || '*' || coalesce(clarity, '')) stored,
    key_value text generated always as
        (coalesce(range_carat, '') || '*' || coalesce(clarity, '') || '*' || coalesce(color, '')) stored
);

create index data_key_kcs_idx on public.data (key_kcs);
create index data_key_value_idx on public.data (key_value);
create index data_report_group_idx on public.data (cert_type, clarity, size);

insert into public.rule_kcs (key_kcs, unchanged, drop_1, drop_2, drop_3, drop_4, drop_5) values
    ('PNJ*IF', 0.25, 0.22499999999999998, 0.375, 0.07500000000000001, 0.037500000000000006, 0.03375),
    ('PNJ*VVS1', 0.35, 0.22749999999999998, 0.29250000000000004, 0.065, 0.0325, 0.029249999999999998),
    ('PNJ+GIA*IF', 0.3, 0.21, 0.35, 0.06999999999999999, 0.034999999999999996, 0.0315),
    ('PNJ+GIA*VS1', 0.5, 0.25, 0.175, 0.05, 0.0225, 0),
    ('PNJ+GIA*VVS1', 0.4, 0.21, 0.27, 0.06, 0.03, 0.027);

insert into public.rule_value (key_value, unchanged, drop_1, drop_2, drop_3, drop_4, drop_5) values
    ('0.3-0.39*IF*D', 0, 0.1481, 0.2222, 0.2963, 0.3704, 0.4444),
    ('0.3-0.39*IF*E', 0, 0.087, 0.1739, 0.2609, 0.3043, 0.3913),
    ('0.3-0.39*IF*F', 0, 0.05, 0.15, 0.2, 0.25, 0.35),
    ('0.3-0.39*IF*G', 0, 0.0556, 0.1111, 0.1667, 0.2222, 0.3333),
    ('0.3-0.39*IF*H', 0, 0.0625, 0.125, 0.1875, 0.25, 0.3125),
    ('0.3-0.39*VVS1*D', 0, 0.087, 0.1739, 0.2609, 0.3478, 0.4348),
    ('0.3-0.39*VVS1*E', 0, 0.0952, 0.1905, 0.2381, 0.3333, 0.4286),
    ('0.3-0.39*VVS1*F', 0, 0.1053, 0.1579, 0.2105, 0.3158, 0.4211),
    ('0.3-0.39*VVS1*G', 0, 0.0588, 0.1176, 0.1765, 0.2941, 0.3529),
    ('0.3-0.39*VVS1*H', 0, 0.0667, 0.1333, 0.2, 0.2667, 0.3333),
    ('0.3-0.39*VS1*D', 0, 0.1053, 0.2105, 0.3158, 0.3684, NULL),
    ('0.3-0.39*VS1*E', 0, 0.0588, 0.1765, 0.2941, 0.3529, NULL),
    ('0.3-0.39*VS1*F', 0, 0.0625, 0.1875, 0.3125, 0.375, NULL),
    ('0.3-0.39*VS1*G', 0, 0.0667, 0.2, 0.2667, 0.3333, NULL),
    ('0.3-0.39*VS1*H', 0, 0.0769, 0.1538, 0.2308, 0.3077, NULL),
    ('0.3-0.39*VS2*D', 0, 0.1176, 0.2353, 0.2941, NULL, NULL),
    ('0.3-0.39*VS2*E', 0, 0.125, 0.25, 0.3125, NULL, NULL),
    ('0.3-0.39*VS2*F', 0, 0.1333, 0.2667, 0.3333, NULL, NULL),
    ('0.3-0.39*VS2*G', 0, 0.1429, 0.2143, 0.2857, NULL, NULL),
    ('0.3-0.39*VS2*H', 0, 0.0833, 0.1667, 0.25, NULL, NULL),
    ('0.4-0.49*IF*D', 0, 0.1935, 0.2581, 0.3226, 0.3871, 0.4516),
    ('0.4-0.49*IF*E', 0, 0.1154, 0.1923, 0.2692, 0.3077, 0.3846),
    ('0.4-0.49*IF*F', 0, 0.087, 0.1739, 0.2174, 0.2609, 0.3478),
    ('0.4-0.49*IF*G', 0, 0.1429, 0.1905, 0.2381, 0.2857, 0.381),
    ('0.4-0.49*IF*H', 0, 0.1111, 0.1667, 0.2222, 0.2778, 0.3333),
    ('0.4-0.49*VVS1*D', 0, 0.08, 0.16, 0.24, 0.32, 0.4),
    ('0.4-0.49*VVS1*E', 0, 0.087, 0.1739, 0.2174, 0.3043, 0.3913),
    ('0.4-0.49*VVS1*F', 0, 0.0952, 0.1429, 0.1905, 0.2857, 0.381),
    ('0.4-0.49*VVS1*G', 0, 0.0556, 0.1111, 0.1667, 0.2778, 0.3333),
    ('0.4-0.49*VVS1*H', 0, 0.0625, 0.125, 0.1875, 0.25, 0.3125),
    ('0.4-0.49*VS1*D', 0, 0.0952, 0.1905, 0.2857, 0.3333, NULL),
    ('0.4-0.49*VS1*E', 0, 0.0526, 0.1579, 0.2632, 0.3158, NULL),
    ('0.4-0.49*VS1*F', 0, 0.0556, 0.1667, 0.2778, 0.3333, NULL),
    ('0.4-0.49*VS1*G', 0, 0.0625, 0.1875, 0.25, 0.3125, NULL),
    ('0.4-0.49*VS1*H', 0, 0.0714, 0.1429, 0.2143, 0.2857, NULL),
    ('0.4-0.49*VS2*D', 0, 0.1053, 0.2105, 0.2632, NULL, NULL),
    ('0.4-0.49*VS2*E', 0, 0.1111, 0.2222, 0.2778, NULL, NULL),
    ('0.4-0.49*VS2*F', 0, 0.1176, 0.2353, 0.2941, NULL, NULL),
    ('0.4-0.49*VS2*G', 0, 0.1333, 0.2, 0.2667, NULL, NULL),
    ('0.4-0.49*VS2*H', 0, 0.0769, 0.1538, 0.2308, NULL, NULL),
    ('0.5-0.69*IF*D', 0, 0.2128, 0.3617, 0.4468, 0.5106, 0.5745),
    ('0.5-0.69*IF*E', 0, 0.1351, 0.2703, 0.3514, 0.4324, 0.5135),
    ('0.5-0.69*IF*F', 0, 0.125, 0.2188, 0.3125, 0.375, 0.4688),
    ('0.5-0.69*IF*G', 0, 0.1111, 0.1852, 0.2593, 0.2963, 0.4074),
    ('0.5-0.69*IF*H', 0, 0.087, 0.1739, 0.2609, 0.3043, 0.3913),
    ('0.5-0.69*VVS1*D', 0, 0.1892, 0.2973, 0.3784, 0.4595, 0.5676),
    ('0.5-0.69*VVS1*E', 0, 0.1563, 0.25, 0.3438, 0.4375, 0.5313),
    ('0.5-0.69*VVS1*F', 0, 0.1071, 0.2143, 0.2857, 0.3929, 0.5),
    ('0.5-0.69*VVS1*G', 0, 0.0833, 0.1667, 0.2083, 0.3333, 0.4583),
    ('0.5-0.69*VVS1*H', 0, 0.0952, 0.1905, 0.2381, 0.3333, 0.4286),
    ('0.5-0.69*VS1*D', 0, 0.1154, 0.2308, 0.3846, 0.4231, NULL),
    ('0.5-0.69*VS1*E', 0, 0.125, 0.25, 0.375, 0.4167, NULL),
    ('0.5-0.69*VS1*F', 0, 0.0909, 0.2273, 0.3636, 0.4091, NULL),
    ('0.5-0.69*VS1*G', 0, 0.05, 0.2, 0.35, 0.4, NULL),
    ('0.5-0.69*VS1*H', 0, 0.0588, 0.1765, 0.2941, 0.3529, NULL),
    ('0.5-0.69*VS2*D', 0, 0.1304, 0.3043, 0.3478, NULL, NULL),
    ('0.5-0.69*VS2*E', 0, 0.1429, 0.2857, 0.3333, NULL, NULL),
    ('0.5-0.69*VS2*F', 0, 0.15, 0.3, 0.35, NULL, NULL),
    ('0.5-0.69*VS2*G', 0, 0.1579, 0.3158, 0.3684, NULL, NULL),
    ('0.5-0.69*VS2*H', 0, 0.125, 0.25, 0.3125, NULL, NULL),
    ('0.7-0.89*IF*D', 0, 0.2031, 0.3594, 0.4531, 0.5313, 0.5938),
    ('0.7-0.89*IF*E', 0, 0.1346, 0.2692, 0.3654, 0.4615, 0.5385),
    ('0.7-0.89*IF*F', 0, 0.1111, 0.2444, 0.3333, 0.4222, 0.5111),
    ('0.7-0.89*IF*G', 0, 0.1316, 0.2105, 0.2895, 0.3684, 0.4737),
    ('0.7-0.89*IF*H', 0, 0.0968, 0.1935, 0.2581, 0.3226, 0.4194),
    ('0.7-0.89*VVS1*D', 0, 0.1961, 0.3137, 0.4118, 0.4902, 0.549),
    ('0.7-0.89*VVS1*E', 0, 0.1556, 0.2667, 0.3778, 0.4667, 0.5333),
    ('0.7-0.89*VVS1*F', 0, 0.15, 0.25, 0.35, 0.45, 0.525),
    ('0.7-0.89*VVS1*G', 0, 0.0909, 0.1818, 0.2727, 0.3939, 0.4848),
    ('0.7-0.89*VVS1*H', 0, 0.1071, 0.1786, 0.25, 0.3571, 0.4286),
    ('0.7-0.89*VS1*D', 0, 0.1429, 0.2571, 0.3429, 0.4, NULL),
    ('0.7-0.89*VS1*E', 0, 0.1515, 0.2727, 0.3636, 0.4242, NULL),
    ('0.7-0.89*VS1*F', 0, 0.1333, 0.2667, 0.3667, 0.4333, NULL),
    ('0.7-0.89*VS1*G', 0, 0.1111, 0.2593, 0.3704, 0.4074, NULL),
    ('0.7-0.89*VS1*H', 0, 0.087, 0.2174, 0.3043, 0.3478, NULL),
    ('0.7-0.89*VS2*D', 0, 0.1333, 0.2333, 0.3, NULL, NULL),
    ('0.7-0.89*VS2*E', 0, 0.1429, 0.25, 0.3214, NULL, NULL),
    ('0.7-0.89*VS2*F', 0, 0.1538, 0.2692, 0.3462, NULL, NULL),
    ('0.7-0.89*VS2*G', 0, 0.1667, 0.2917, 0.3333, NULL, NULL),
    ('0.7-0.89*VS2*H', 0, 0.1429, 0.2381, 0.2857, NULL, NULL),
    ('0.9-0.99*IF*D', 0, 0.1458, 0.3542, 0.4479, 0.5313, 0.625),
    ('0.9-0.99*IF*E', 0, 0.1446, 0.3133, 0.4217, 0.506, 0.6145),
    ('0.9-0.99*IF*F', 0, 0.137, 0.2877, 0.3973, 0.4795, 0.589),
    ('0.9-0.99*IF*G', 0, 0.1186, 0.2373, 0.322, 0.4068, 0.5254),
    ('0.9-0.99*IF*H', 0, 0.0851, 0.1702, 0.2766, 0.3404, 0.4468),
    ('0.9-0.99*VVS1*D', 0, 0.2439, 0.3537, 0.4512, 0.561, 0.6463),
    ('0.9-0.99*VVS1*E', 0, 0.1972, 0.3239, 0.4225, 0.5493, 0.6338),
    ('0.9-0.99*VVS1*F', 0, 0.1746, 0.3016, 0.3968, 0.5238, 0.619),
    ('0.9-0.99*VVS1*G', 0, 0.1346, 0.2308, 0.3269, 0.4615, 0.5577),
    ('0.9-0.99*VVS1*H', 0, 0.093, 0.2093, 0.2791, 0.3953, 0.4884),
    ('0.9-0.99*VS1*D', 0, 0.1509, 0.3208, 0.4528, 0.5094, NULL),
    ('0.9-0.99*VS1*E', 0, 0.1458, 0.3333, 0.4583, 0.5, NULL),
    ('0.9-0.99*VS1*F', 0, 0.1364, 0.3182, 0.4545, 0.5, NULL),
    ('0.9-0.99*VS1*G', 0, 0.125, 0.3, 0.425, 0.475, NULL),
    ('0.9-0.99*VS1*H', 0, 0.0882, 0.2353, 0.3529, 0.4118, NULL),
    ('0.9-0.99*VS2*D', 0, 0.2, 0.3556, 0.4222, NULL, NULL),
    ('0.9-0.99*VS2*E', 0, 0.2195, 0.3659, 0.4146, NULL, NULL),
    ('0.9-0.99*VS2*F', 0, 0.2105, 0.3684, 0.4211, NULL, NULL),
    ('0.9-0.99*VS2*G', 0, 0.2, 0.3429, 0.4, NULL, NULL),
    ('0.9-0.99*VS2*H', 0, 0.1613, 0.2903, 0.3548, NULL, NULL),
    ('1-1.49*IF*D', 0, 0.2133, 0.4067, 0.4933, 0.58, 0.68),
    ('1-1.49*IF*E', 0, 0.113, 0.2957, 0.4, 0.5043, 0.6174),
    ('1-1.49*IF*F', 0, 0.0938, 0.2292, 0.3438, 0.4583, 0.5729),
    ('1-1.49*IF*G', 0, 0.0933, 0.1733, 0.28, 0.3733, 0.5067),
    ('1-1.49*IF*H', 0, 0.0862, 0.1552, 0.2241, 0.2759, 0.4138),
    ('1-1.49*VVS1*D', 0, 0.2458, 0.3559, 0.4661, 0.5932, 0.6864),
    ('1-1.49*VVS1*E', 0, 0.2059, 0.3235, 0.4412, 0.5686, 0.6667),
    ('1-1.49*VVS1*F', 0, 0.1494, 0.2759, 0.4023, 0.5287, 0.6322),
    ('1-1.49*VVS1*G', 0, 0.0882, 0.2059, 0.3088, 0.4559, 0.5588),
    ('1-1.49*VVS1*H', 0, 0.0755, 0.1509, 0.2075, 0.3585, 0.4717),
    ('1-1.49*VS1*D', 0, 0.1711, 0.3684, 0.5132, 0.5789, NULL),
    ('1-1.49*VS1*E', 0, 0.1739, 0.3623, 0.5072, 0.5652, NULL),
    ('1-1.49*VS1*F', 0, 0.1746, 0.3492, 0.4921, 0.5556, NULL),
    ('1-1.49*VS1*G', 0, 0.1296, 0.3148, 0.4444, 0.5185, NULL),
    ('1-1.49*VS1*H', 0, 0.0667, 0.2444, 0.3778, 0.4444, NULL),
    ('1-1.49*VS2*D', 0, 0.2381, 0.4127, 0.4921, NULL, NULL),
    ('1-1.49*VS2*E', 0, 0.2281, 0.4035, 0.4737, NULL, NULL),
    ('1-1.49*VS2*F', 0, 0.2115, 0.3846, 0.4615, NULL, NULL),
    ('1-1.49*VS2*G', 0, 0.2128, 0.3617, 0.4468, NULL, NULL),
    ('1-1.49*VS2*H', 0, 0.1905, 0.3333, 0.4048, NULL, NULL),
    ('1.5-1.99*IF*D', 0, 0.11, 0.27, 0.365, 0.43, 0.56),
    ('1.5-1.99*IF*E', 0, 0.0838, 0.2402, 0.352, 0.4134, 0.5419),
    ('1.5-1.99*IF*F', 0, 0.0705, 0.1987, 0.3077, 0.3718, 0.5064),
    ('1.5-1.99*IF*G', 0, 0.0698, 0.1628, 0.2713, 0.3411, 0.4496),
    ('1.5-1.99*IF*H', 0, 0.0777, 0.165, 0.2524, 0.3204, 0.3883),
    ('1.5-1.99*VVS1*D', 0, 0.1798, 0.2865, 0.3596, 0.5056, 0.6011),
    ('1.5-1.99*VVS1*E', 0, 0.1707, 0.2927, 0.3598, 0.5, 0.6037),
    ('1.5-1.99*VVS1*F', 0, 0.1379, 0.2552, 0.3241, 0.469, 0.5793),
    ('1.5-1.99*VVS1*G', 0, 0.1, 0.2167, 0.2917, 0.4083, 0.525),
    ('1.5-1.99*VVS1*H', 0, 0.0947, 0.1895, 0.2632, 0.3368, 0.4526),
    ('1.5-1.99*VS1*D', 0, 0.1024, 0.3071, 0.4409, 0.5039, NULL),
    ('1.5-1.99*VS1*E', 0, 0.0948, 0.2931, 0.4397, 0.5086, NULL),
    ('1.5-1.99*VS1*F', 0, 0.0926, 0.287, 0.4352, 0.5, NULL),
    ('1.5-1.99*VS1*G', 0, 0.0957, 0.2447, 0.3936, 0.4574, NULL),
    ('1.5-1.99*VS1*H', 0, 0.0909, 0.1818, 0.3247, 0.3766, NULL),
    ('1.5-1.99*VS2*D', 0, 0.2281, 0.3772, 0.4474, NULL, NULL),
    ('1.5-1.99*VS2*E', 0, 0.219, 0.381, 0.4571, NULL, NULL),
    ('1.5-1.99*VS2*F', 0, 0.2143, 0.3776, 0.449, NULL, NULL),
    ('1.5-1.99*VS2*G', 0, 0.1647, 0.3294, 0.4, NULL, NULL),
    ('1.5-1.99*VS2*H', 0, 0.1, 0.2571, 0.3143, NULL, NULL),
    ('2-2.99*IF*D', 0, 0.1667, 0.2879, 0.3788, 0.4697, 0.5727),
    ('2-2.99*IF*E', 0, 0.0926, 0.2222, 0.2963, 0.4074, 0.5111),
    ('2-2.99*IF*F', 0, 0.102, 0.2041, 0.2857, 0.3878, 0.498),
    ('2-2.99*IF*G', 0, 0.0976, 0.1951, 0.2683, 0.3415, 0.4537),
    ('2-2.99*IF*H', 0, 0.0909, 0.1818, 0.2424, 0.303, 0.3697),
    ('2-2.99*VVS1*D', 0, 0.1455, 0.2545, 0.3636, 0.4873, 0.5891),
    ('2-2.99*VVS1*E', 0, 0.1429, 0.2245, 0.3469, 0.4612, 0.5714),
    ('2-2.99*VVS1*F', 0, 0.1136, 0.2045, 0.3182, 0.4409, 0.5545),
    ('2-2.99*VVS1*G', 0, 0.1081, 0.1892, 0.2703, 0.3946, 0.5027),
    ('2-2.99*VVS1*H', 0, 0.1, 0.1667, 0.2333, 0.3067, 0.4267),
    ('2-2.99*VS1*D', 0, 0.1463, 0.3122, 0.4488, 0.5366, NULL),
    ('2-2.99*VS1*E', 0, 0.1579, 0.3053, 0.4474, 0.5368, NULL),
    ('2-2.99*VS1*F', 0, 0.1429, 0.2971, 0.44, 0.5257, NULL),
    ('2-2.99*VS1*G', 0, 0.1, 0.2533, 0.3867, 0.4867, NULL),
    ('2-2.99*VS1*H', 0, 0.08, 0.168, 0.312, 0.432, NULL),
    ('2-2.99*VS2*D', 0, 0.1943, 0.3543, 0.4571, NULL, NULL),
    ('2-2.99*VS2*E', 0, 0.175, 0.3438, 0.45, NULL, NULL),
    ('2-2.99*VS2*F', 0, 0.18, 0.3467, 0.4467, NULL, NULL),
    ('2-2.99*VS2*G', 0, 0.1704, 0.3185, 0.4296, NULL, NULL),
    ('2-2.99*VS2*H', 0, 0.0957, 0.2522, 0.3826, NULL, NULL),
    ('3-3.99*IF*D', 0, 0.1636, 0.2545, 0.3636, 0.4636, 0.5727),
    ('3-3.99*IF*E', 0, 0.0667, 0.1778, 0.2889, 0.4111, 0.5333),
    ('3-3.99*IF*F', 0, 0.0741, 0.1728, 0.2716, 0.3951, 0.5185),
    ('3-3.99*IF*G', 0, 0.0597, 0.1642, 0.2687, 0.3731, 0.4627),
    ('3-3.99*IF*H', 0, 0.0741, 0.1667, 0.2407, 0.3148, 0.4074),
    ('3-3.99*VVS1*D', 0, 0.1087, 0.2391, 0.3587, 0.4891, 0.5652),
    ('3-3.99*VVS1*E', 0, 0.119, 0.2381, 0.369, 0.5, 0.5595),
    ('3-3.99*VVS1*F', 0, 0.1067, 0.2133, 0.3467, 0.48, 0.5467),
    ('3-3.99*VVS1*G', 0, 0.1111, 0.2222, 0.3333, 0.4286, 0.5079),
    ('3-3.99*VVS1*H', 0, 0.1, 0.18, 0.26, 0.36, 0.46),
    ('3-3.99*VS1*D', 0, 0.1571, 0.3286, 0.4286, 0.6029, NULL),
    ('3-3.99*VS1*E', 0, 0.1719, 0.3438, 0.4219, 0.5906, NULL),
    ('3-3.99*VS1*F', 0, 0.1695, 0.339, 0.4237, 0.5797, NULL),
    ('3-3.99*VS1*G', 0, 0.1429, 0.2653, 0.3673, 0.5429, NULL),
    ('3-3.99*VS1*H', 0, 0.0976, 0.2195, 0.3415, 0.5073, NULL),
    ('3-3.99*VS2*D', 0, 0.2034, 0.322, 0.5288, NULL, NULL),
    ('3-3.99*VS2*E', 0, 0.2075, 0.3019, 0.5057, NULL, NULL),
    ('3-3.99*VS2*F', 0, 0.2041, 0.3061, 0.4939, NULL, NULL),
    ('3-3.99*VS2*G', 0, 0.1429, 0.2619, 0.4667, NULL, NULL),
    ('3-3.99*VS2*H', 0, 0.1351, 0.2703, 0.4541, NULL, NULL),
    ('4-4.99*IF*D', 0, 0.1342, 0.2148, 0.3356, 0.443, 0.5772),
    ('4-4.99*IF*E', 0, 0.064, 0.16, 0.28, 0.376, 0.528),
    ('4-4.99*IF*F', 0, 0.0796, 0.1593, 0.2743, 0.3717, 0.5133),
    ('4-4.99*IF*G', 0, 0.0753, 0.1505, 0.2258, 0.3226, 0.4731),
    ('4-4.99*IF*H', 0, 0.0694, 0.125, 0.1806, 0.2778, 0.4028),
    ('4-4.99*VVS1*D', 0, 0.093, 0.2326, 0.3566, 0.5116, 0.6047),
    ('4-4.99*VVS1*E', 0, 0.1026, 0.2308, 0.3333, 0.4957, 0.5897),
    ('4-4.99*VVS1*F', 0, 0.0865, 0.2115, 0.3173, 0.4712, 0.5673),
    ('4-4.99*VVS1*G', 0, 0.0814, 0.1628, 0.2674, 0.4302, 0.5349),
    ('4-4.99*VVS1*H', 0, 0.0597, 0.1194, 0.2239, 0.3582, 0.4627),
    ('4-4.99*VS1*D', 0, 0.1616, 0.3636, 0.4848, 0.6869, NULL),
    ('4-4.99*VS1*E', 0, 0.1333, 0.3444, 0.4667, 0.6778, NULL),
    ('4-4.99*VS1*F', 0, 0.1341, 0.3293, 0.4512, 0.6634, NULL),
    ('4-4.99*VS1*G', 0, 0.125, 0.3194, 0.4444, 0.6472, NULL),
    ('4-4.99*VS1*H', 0, 0.1186, 0.2712, 0.3898, 0.6136, NULL),
    ('4-4.99*VS2*D', 0, 0.241, 0.3855, 0.6265, NULL, NULL),
    ('4-4.99*VS2*E', 0, 0.2436, 0.3846, 0.6282, NULL, NULL),
    ('4-4.99*VS2*F', 0, 0.2254, 0.3662, 0.6113, NULL, NULL),
    ('4-4.99*VS2*G', 0, 0.2222, 0.3651, 0.5968, NULL, NULL),
    ('4-4.99*VS2*H', 0, 0.1731, 0.3077, 0.5615, NULL, NULL),
    ('0.15-0.17*IF*D', 0, 0.1481, 0.2222, 0.2963, 0.3704, 0.4444),
    ('0.15-0.17*IF*E', 0, 0.087, 0.1739, 0.2609, 0.3043, 0.3913),
    ('0.15-0.17*IF*F', 0, 0.05, 0.15, 0.2, 0.25, 0.35),
    ('0.15-0.17*IF*G', 0, 0.0556, 0.1111, 0.1667, 0.2222, 0.3333),
    ('0.15-0.17*IF*H', 0, 0.0625, 0.125, 0.1875, 0.25, 0.3125),
    ('0.15-0.17*VVS1*D', 0, 0.087, 0.1739, 0.2609, 0.3478, 0.4348),
    ('0.15-0.17*VVS1*E', 0, 0.0952, 0.1905, 0.2381, 0.3333, 0.4286),
    ('0.15-0.17*VVS1*F', 0, 0.1053, 0.1579, 0.2105, 0.3158, 0.4211),
    ('0.15-0.17*VVS1*G', 0, 0.0588, 0.1176, 0.1765, 0.2941, 0.3529),
    ('0.15-0.17*VVS1*H', 0, 0.0667, 0.1333, 0.2, 0.2667, 0.3333),
    ('0.15-0.17*VS1*D', 0, 0.1053, 0.2105, 0.3158, 0.3684, NULL),
    ('0.15-0.17*VS1*E', 0, 0.0588, 0.1765, 0.2941, 0.3529, NULL),
    ('0.15-0.17*VS1*F', 0, 0.0625, 0.1875, 0.3125, 0.375, NULL),
    ('0.15-0.17*VS1*G', 0, 0.0667, 0.2, 0.2667, 0.3333, NULL),
    ('0.15-0.17*VS1*H', 0, 0.0769, 0.1538, 0.2308, 0.3077, NULL),
    ('0.15-0.17*VS2*D', 0, 0.1176, 0.2353, 0.2941, NULL, NULL),
    ('0.15-0.17*VS2*E', 0, 0.125, 0.25, 0.3125, NULL, NULL),
    ('0.15-0.17*VS2*F', 0, 0.1333, 0.2667, 0.3333, NULL, NULL),
    ('0.15-0.17*VS2*G', 0, 0.1429, 0.2143, 0.2857, NULL, NULL),
    ('0.15-0.17*VS2*H', 0, 0.0833, 0.1667, 0.25, NULL, NULL),
    ('0.18-0.22*IF*D', 0, 0.1481, 0.2222, 0.2963, 0.3704, 0.4444),
    ('0.18-0.22*IF*E', 0, 0.087, 0.1739, 0.2609, 0.3043, 0.3913),
    ('0.18-0.22*IF*F', 0, 0.05, 0.15, 0.2, 0.25, 0.35),
    ('0.18-0.22*IF*G', 0, 0.0556, 0.1111, 0.1667, 0.2222, 0.3333),
    ('0.18-0.22*IF*H', 0, 0.0625, 0.125, 0.1875, 0.25, 0.3125),
    ('0.18-0.22*VVS1*D', 0, 0.087, 0.1739, 0.2609, 0.3478, 0.4348),
    ('0.18-0.22*VVS1*E', 0, 0.0952, 0.1905, 0.2381, 0.3333, 0.4286),
    ('0.18-0.22*VVS1*F', 0, 0.1053, 0.1579, 0.2105, 0.3158, 0.4211),
    ('0.18-0.22*VVS1*G', 0, 0.0588, 0.1176, 0.1765, 0.2941, 0.3529),
    ('0.18-0.22*VVS1*H', 0, 0.0667, 0.1333, 0.2, 0.2667, 0.3333),
    ('0.18-0.22*VS1*D', 0, 0.1053, 0.2105, 0.3158, 0.3684, NULL),
    ('0.18-0.22*VS1*E', 0, 0.0588, 0.1765, 0.2941, 0.3529, NULL),
    ('0.18-0.22*VS1*F', 0, 0.0625, 0.1875, 0.3125, 0.375, NULL),
    ('0.18-0.22*VS1*G', 0, 0.0667, 0.2, 0.2667, 0.3333, NULL),
    ('0.18-0.22*VS1*H', 0, 0.0769, 0.1538, 0.2308, 0.3077, NULL),
    ('0.18-0.22*VS2*D', 0, 0.1176, 0.2353, 0.2941, NULL, NULL),
    ('0.18-0.22*VS2*E', 0, 0.125, 0.25, 0.3125, NULL, NULL),
    ('0.18-0.22*VS2*F', 0, 0.1333, 0.2667, 0.3333, NULL, NULL),
    ('0.18-0.22*VS2*G', 0, 0.1429, 0.2143, 0.2857, NULL, NULL),
    ('0.18-0.22*VS2*H', 0, 0.0833, 0.1667, 0.25, NULL, NULL),
    ('0.23-0.29*IF*D', 0, 0.1481, 0.2222, 0.2963, 0.3704, 0.4444),
    ('0.23-0.29*IF*E', 0, 0.087, 0.1739, 0.2609, 0.3043, 0.3913),
    ('0.23-0.29*IF*F', 0, 0.05, 0.15, 0.2, 0.25, 0.35),
    ('0.23-0.29*IF*G', 0, 0.0556, 0.1111, 0.1667, 0.2222, 0.3333),
    ('0.23-0.29*IF*H', 0, 0.0625, 0.125, 0.1875, 0.25, 0.3125),
    ('0.23-0.29*VVS1*D', 0, 0.087, 0.1739, 0.2609, 0.3478, 0.4348),
    ('0.23-0.29*VVS1*E', 0, 0.0952, 0.1905, 0.2381, 0.3333, 0.4286),
    ('0.23-0.29*VVS1*F', 0, 0.1053, 0.1579, 0.2105, 0.3158, 0.4211),
    ('0.23-0.29*VVS1*G', 0, 0.0588, 0.1176, 0.1765, 0.2941, 0.3529),
    ('0.23-0.29*VVS1*H', 0, 0.0667, 0.1333, 0.2, 0.2667, 0.3333),
    ('0.23-0.29*VS1*D', 0, 0.1053, 0.2105, 0.3158, 0.3684, NULL),
    ('0.23-0.29*VS1*E', 0, 0.0588, 0.1765, 0.2941, 0.3529, NULL),
    ('0.23-0.29*VS1*F', 0, 0.0625, 0.1875, 0.3125, 0.375, NULL),
    ('0.23-0.29*VS1*G', 0, 0.0667, 0.2, 0.2667, 0.3333, NULL),
    ('0.23-0.29*VS1*H', 0, 0.0769, 0.1538, 0.2308, 0.3077, NULL),
    ('0.23-0.29*VS2*D', 0, 0.1176, 0.2353, 0.2941, NULL, NULL),
    ('0.23-0.29*VS2*E', 0, 0.125, 0.25, 0.3125, NULL, NULL),
    ('0.23-0.29*VS2*F', 0, 0.1333, 0.2667, 0.3333, NULL, NULL),
    ('0.23-0.29*VS2*G', 0, 0.1429, 0.2143, 0.2857, NULL, NULL),
    ('0.23-0.29*VS2*H', 0, 0.0833, 0.1667, 0.25, NULL, NULL);

-- LEFT JOIN retains inventory rows with missing rule keys.
create view public.data_calculated with (security_invoker = true) as
select d.*,
    k.unchanged * v.unchanged as unchanged,
    k.drop_1 * v.drop_1 as drop_1,
    k.drop_2 * v.drop_2 as drop_2,
    k.drop_3 * v.drop_3 as drop_3,
    k.drop_4 * v.drop_4 as drop_4,
    k.drop_5 * v.drop_5 as drop_5,
    (k.key_kcs is null or v.key_value is null) as missing_key,
    case
        when k.key_kcs is null and v.key_value is null then
            'Chưa có khóa: Key_KCS=' || d.key_kcs || '; Key_Value=' || d.key_value
        when k.key_kcs is null then 'Chưa có khóa: Key_KCS=' || d.key_kcs
        when v.key_value is null then 'Chưa có khóa: Key_Value=' || d.key_value
        when k.unchanged is null or v.unchanged is null or k.drop_1 is null or v.drop_1 is null or k.drop_2 is null or v.drop_2 is null or k.drop_3 is null or v.drop_3 is null or k.drop_4 is null or v.drop_4 is null or k.drop_5 is null or v.drop_5 is null then 'Thiếu tỷ lệ trong Rule'
        else null
    end as note
from public.data d
left join public.rule_kcs k on k.key_kcs = d.key_kcs
left join public.rule_value v on v.key_value = d.key_value;

-- Supabase may otherwise grant default table privileges to browser roles.
alter table public.data enable row level security;
revoke all on table public.data from anon, authenticated;
grant all on table public.data to service_role;
alter table public.rule_kcs enable row level security;
revoke all on table public.rule_kcs from anon, authenticated;
grant all on table public.rule_kcs to service_role;
alter table public.rule_value enable row level security;
revoke all on table public.rule_value from anon, authenticated;
grant all on table public.rule_value to service_role;
revoke all on table public.data_calculated from anon, authenticated;
grant select on table public.data_calculated to service_role;
revoke all on sequence public.data_id_seq from anon, authenticated;
grant usage, select on sequence public.data_id_seq to service_role;

commit;

-- After importing data.csv:
-- select count(*) from public.data; -- expected: 18729 for this workbook
-- select key_kcs, count(*) from public.data_calculated
-- where missing_key group by key_kcs order by count(*) desc;
-- select * from public.data_calculated where note is not null;
-- Example formatting ONLY: to_char(unchanged * 100, 'FM990.00') || '%'
-- Never place a service_role key in HTML or a GitHub repository.
