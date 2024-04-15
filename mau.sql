
-- First get the monthly active users (MAU) for each month
WITH mau AS (
    SELECT
        date_trunc('month', date) AS month,
        count(DISTINCT user_id) AS mau
    FROM
        user_activity
    GROUP BY
        1
)
-- Then join the MAU table with itself to get the previous month's MAU
-- so we can calculate the change in MAU.
SELECT
    current_month.month,
    current_month.mau,
    previous_month.mau AS previous_mau,
    (current_month.mau - previous_month.mau)::float / previous_month.mau AS change
FROM
    mau current_month
JOIN
    mau previous_month
ON
    current_month.month = previous_month.month + interval '1 month';
