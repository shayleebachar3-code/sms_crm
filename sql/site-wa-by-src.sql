-- לחיצות על כפתור הוואטסאפ באתר + ביקורים, לפי מקור (לטאב "מקורות והמרות").
-- הורצה כבר על הפרויקט. נשמר כאן לתיעוד. אותה לוגיקה כמו site_stats: בלי ביקורים של הבעלים, שעון ישראל, מנהלי CRM בלבד.
create or replace function public.site_wa_by_src(p_from date, p_to date)
returns jsonb language plpgsql stable security definer set search_path to '' as $$
declare r jsonb;
begin
  if not public.is_crm_admin() then raise exception 'not allowed'; end if;
  with e as (
    select * from public.site_events s
    where (s.at at time zone 'Asia/Jerusalem')::date between p_from and p_to
      and not exists (select 1 from public.site_events o where o.ev = 'nav' and o.sec = 'owner' and o.vid = s.vid)
  ),
  sess as (select sid, min(src) src from e group by sid),
  wa as (select sid, count(*) clicks from e where ev = 'wa' group by sid)
  select jsonb_build_object(
    'sessions', (select count(*) from sess),
    'wa_sessions', (select count(*) from wa),
    'wa_clicks', (select coalesce(sum(clicks), 0) from wa),
    'by_src', (select coalesce(jsonb_object_agg(k, jsonb_build_object('sessions', s, 'wa_sessions', w, 'wa_clicks', c)), '{}'::jsonb)
               from (select coalesce(sess.src, 'ישיר') k, count(*) s, count(wa.sid) w, coalesce(sum(wa.clicks), 0) c
                     from sess left join wa on wa.sid = sess.sid group by 1) q)
  ) into r;
  return r;
end $$;
revoke all on function public.site_wa_by_src(date, date) from public, anon;
grant execute on function public.site_wa_by_src(date, date) to authenticated, service_role;
