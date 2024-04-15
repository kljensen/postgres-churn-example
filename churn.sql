
with monthly_activity as (
  select distinct
    date_trunc('month', "date") as month,
    user_id
  from user_activity
)
select
  last_month.month + '1 month'::interval as "month",
  count(distinct last_month.user_id) num_churned
from monthly_activity last_month
left join monthly_activity this_month
  on this_month.user_id = last_month.user_id
  and this_month.month = last_month.month + '1 month'::interval
where this_month.user_id is null
group by 1;

-- Notice that this query will not have any rows
-- for months in which there is no user activity.
-- Really we should use a `CROSS JOIN` with
-- generate_series to ensure we have a row for
-- every month in the date range.