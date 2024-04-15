-- Compute a 7-day rolling average of daily active users (DAU)
-- for each day in the user_activity table.
WITH dau AS (
    SELECT
        date_trunc('day', "date") AS "date",
        count(DISTINCT user_id) AS dau
    FROM
        user_activity
    GROUP BY
        1
)
SELECT
    "date",
    dau,
    avg(dau) OVER (ORDER BY "date" ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS dau_7d
    FROM
        dau
        -- Avoid the first day...don't want to include it
        -- in the rolling average.
    WHERE
        "date" >(
            SELECT
                min("date")
            FROM
                dau)
    ORDER BY
        "date";

