with monthly_activity as (
  select distinct
    date_trunc('month', date) as month,
    user_id
  from user_activity
)
select
  current.month,
  count(distinct current.user_id)
from monthly_activity current
join monthly_activity previous
  on current.user_id = previous.user_id
  and current.month = previous.month + interval '1 month'
group by current.month;