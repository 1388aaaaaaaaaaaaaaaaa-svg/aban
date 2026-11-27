-- حذف آخرین قبض صادرشده (برای اشتباهات). کنتور هر واحد خودکار به عدد قبل از این قبض برمی‌گردد
-- چون عدد قبلی هر قبض از آخرین قبض منتشرشده خوانده می‌شود.
create or replace function public.manager_delete_period(p_token uuid, p_period uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_b uuid;
  v_latest uuid;
  v_title text;
begin
  v_b := public.session_building(p_token);
  if v_b is null then raise exception 'SESSION_INVALID'; end if;

  select p.id, p.title into v_latest, v_title
  from public.billing_periods p
  where p.building_id = v_b and p.status in ('published','closed')
  order by p.created_at desc
  limit 1;

  if v_latest is null or v_latest <> p_period then
    raise exception 'ONLY_LATEST_PERIOD';
  end if;

  delete from public.tariff_snapshots where period_id = p_period;
  delete from public.meter_readings where period_id = p_period;
  delete from public.bills where period_id = p_period and building_id = v_b;
  delete from public.billing_periods where id = p_period and building_id = v_b;

  insert into public.activity_log (building_id, actor, action, details)
  values (v_b, 'manager', 'حذف قبض', v_title);

  return true;
end $$;

grant execute on function public.manager_delete_period(uuid, uuid) to anon, authenticated;
