

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE IF NOT EXISTS users(
    id INT PRIMARY KEY,
    cohort INT NOT NULL CHECK (cohort >= 1 AND cohort <= 5),
    demographic TEXT NOT NULL CHECK (demographic IN ('A', 'B', 'C', 'D', 'E'))
);

DROP TABLE IF EXISTS user_activity;
CREATE TABLE IF NOT EXISTS user_activity(
    user_id int REFERENCES users(id),
    "date" DATE NOT NULL
);

-- A function that returns a sample from the normal
-- distribution with the given mean and standard deviation.
CREATE OR REPLACE FUNCTION normal_sample(mean float, stddev float)
    RETURNS float
    AS $$
BEGIN
    RETURN stddev * sqrt(-2.0 * ln(random())) * cos(2.0 * pi() * random()) + mean;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION positive_int_normal_sample(mean float, stddev float)
    RETURNS int
    AS $$
BEGIN
    RETURN abs(normal_sample(mean, stddev))::int + 1;
END;
$$
LANGUAGE plpgsql;


-- Now we have a PL/pgSQL function that will
-- help us populate some realistic data.
CREATE OR REPLACE FUNCTION generate_user_activity_v2(total_users integer, start_date date, end_date date)
    RETURNS void
    AS $$
DECLARE
    cohort_distribution int[] := ARRAY[20, 20, 20, 20, 20];
    -- Percentage of users in each cohort
    churn_rates float[] := ARRAY[0.05, 0.10, 0.15, 0.20, 0.25];
    -- Churn rates for each cohort
    user_cohort int;
    signup_date date;
    activity_date date;
    demographic char;
    user_id int;
    activity_delay int;
    churn_chance float;
    days_active int;
    days_range int;
BEGIN
    days_range := end_date - start_date;
    FOR user_id IN 1..total_users LOOP
        IF random() < 0.2 THEN
            -- Make 20% of the users "pre-existing" users
            signup_date := start_date;
        ELSE
            -- Randomize the sign-up date within the date range
            signup_date := start_date +(random() * days_range)::int;
        END IF;
        -- Determine the cohort by weighted random selection based on distribution
        user_cohort := width_bucket(random(), ARRAY[0, 0.2, 0.4, 0.6, 0.8]);
        -- Get a random demographic for the user in the set {A, B, C, D, E}
        demographic := chr(65 + width_bucket(random(), ARRAY[0, 0.2, 0.4, 0.6, 0.8]) - 1);

        -- Insert user record
        INSERT INTO users(id, cohort, demographic)
            VALUES (user_id, user_cohort, demographic);
        -- Initialize the user activity starting from their sign-up date
        activity_date := signup_date;
        churn_chance := churn_rates[user_cohort];
        -- Simulate user activity until they churn or reach the end_date
        WHILE activity_date <= end_date
            AND random() > churn_chance LOOP
                -- Insert activity record
                INSERT INTO user_activity(user_id, date)
                    VALUES (user_id, activity_date);
                -- Set activity_delay based on demographic. Each deomographic
                -- has a mean and standard deviation for the delay between
                -- activities.
                IF demographic = 'A' THEN
                    activity_delay := positive_int_normal_sample(2, 1);
                ELSIF demographic = 'B' THEN
                    activity_delay := positive_int_normal_sample(10, 2);
                ELSIF demographic = 'C' THEN
                    activity_delay := positive_int_normal_sample(5, 4);
                ELSIF demographic = 'D' THEN
                    activity_delay := positive_int_normal_sample(1, 1);
                ELSIF demographic = 'E' THEN
                    activity_delay := positive_int_normal_sample(20, 5);
                END IF;
                activity_date := activity_date + activity_delay;
        
                -- Increase churn chance slightly each day
                churn_chance := churn_chance * 1.01;
                days_active := days_active + 1;
            END LOOP;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Now we can generate some realistic data
SELECT generate_user_activity_v2(5000, '2020-01-01', '2022-12-31');
