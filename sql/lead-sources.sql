-- ש.מ.ש משקאות: לידים לפי מקור וקמפיין
-- חלק א: שאילתות קריאה בלבד. אפשר להריץ ב-SQL Editor של Supabase בכל רגע, הן לא משנות כלום.
-- חלק ב: מיגרציה אופציונלית. לא הורצה. רצה רק אחרי אישור של שי.
-- האתר לא צריך שום עמודה חדשה: הפרטים נשמרים ב-clients.prefs -> 'attribution' (עמודה שכבר פתוחה להכנסה מהאתר).

-- ===== חלק א1: לפי מקור (כמו שמופיע ב-CRM) =====
select coalesce(nullif(source, ''), 'ישיר / המלצה')                          as "מקור",
       count(*)                                                              as "לידים",
       count(*) filter (where status = 'נסגרה עסקה')                         as "נסגרו",
       round(100.0 * count(*) filter (where status = 'נסגרה עסקה') / nullif(count(*), 0)) as "% סגירה",
       coalesce(sum(value) filter (where status = 'נסגרה עסקה'), 0)          as "הכנסה (כולל מע״מ)",
       min(created_at)::date                                                 as "ליד ראשון",
       max(created_at)::date                                                 as "ליד אחרון"
from public.clients
where coalesce(is_example, false) = false
  and created_at >= now() - interval '90 days'          -- לשנות לפי התקופה
group by 1
order by 2 desc;

-- ===== חלק א2: רשת / סוג / קמפיין / קהל / מודעה (רק לידים מהאתר עם פרטי הגעה) =====
select coalesce(prefs->'attribution'->>'net', prefs->'attribution'->>'label') as "רשת",
       coalesce(prefs->'attribution'->>'kind', '—')                          as "סוג",
       coalesce(prefs->'attribution'->>'utm_campaign', '—')                  as "קמפיין",
       coalesce(prefs->'attribution'->>'utm_term', '—')                      as "קהל",
       coalesce(prefs->'attribution'->>'utm_content', '—')                   as "מודעה",
       count(*)                                                              as "לידים",
       count(*) filter (where status = 'נסגרה עסקה')                         as "נסגרו",
       coalesce(sum(value) filter (where status = 'נסגרה עסקה'), 0)          as "הכנסה"
from public.clients
where coalesce(is_example, false) = false
  and prefs ? 'attribution'
group by 1, 2, 3, 4, 5
order by 6 desc;

-- ===== חלק ב (אופציונלי, לא הורץ): view קבוע לדוח + מקור בהתראת ליד חדש =====
-- view עם security_invoker: מכבד את ה-RLS, כלומר רק מנהלי CRM מחוברים רואים נתונים. anon לא מקבל גישה.
-- create or replace view public.lead_sources
-- with (security_invoker = true) as
-- select c.id, c.created_at, c.status, c.value, c.source,
--        c.prefs->'attribution'->>'net'          as net,
--        c.prefs->'attribution'->>'kind'         as kind,
--        c.prefs->'attribution'->>'utm_source'   as utm_source,
--        c.prefs->'attribution'->>'utm_medium'   as utm_medium,
--        c.prefs->'attribution'->>'utm_campaign' as utm_campaign,
--        c.prefs->'attribution'->>'utm_term'     as utm_term,
--        c.prefs->'attribution'->>'utm_content'  as utm_content,
--        c.prefs->'attribution'->>'referrer_host' as referrer_host,
--        c.prefs->'attribution'->>'app'          as in_app,
--        c.prefs->'attribution'->>'first_touch'  as first_touch
-- from public.clients c
-- where coalesce(c.is_example, false) = false;
-- revoke all on public.lead_sources from anon;
-- grant select on public.lead_sources to authenticated;
--
-- הערה חשובה: אם בעתיד מוסיפים עמודות utm_* אמיתיות לטבלה clients, צריך גם GRANT INSERT (עמודה) ל-anon,
-- אחרת כל שליחת טופס שכוללת אותן תיכשל. לכן האתר כרגע כותב רק ל-prefs, ולא צריך את זה.
