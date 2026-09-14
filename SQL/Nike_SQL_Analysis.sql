USE nike_insights_2025;

-- Q1. Platform Comparison:
-- Total views and average engagement rate by platform

SELECT
    platform,
    SUM(views) AS total_views,
    ROUND(AVG(engagement_rate) * 100, 2) AS avg_engagement_rate_pct
FROM nike_videos
GROUP BY platform
ORDER BY total_views DESC;

-- Q2. Regional Hotspots:
-- Top 5 countries by total views on each platform

WITH country_views AS (
    SELECT
        platform,
        UPPER(country) AS country,
        SUM(views) AS total_views
    FROM nike_insights_2025.nike_videos
    GROUP BY platform, UPPER(country)
),
ranked_countries AS (
    SELECT
        platform,
        country,
        total_views,
        ROW_NUMBER() OVER (
            PARTITION BY platform
            ORDER BY total_views DESC, country ASC
        ) AS country_rank
    FROM country_views
)
SELECT
    platform,
    country_rank,
    country,
    total_views
FROM ranked_countries
WHERE country_rank <= 5
ORDER BY platform, country_rank;


-- Q3. Category Performance:
-- Average completion rate and watch time by category

SELECT
    category,
    ROUND(AVG(completion_rate) * 100, 2)
        AS avg_completion_rate_pct,
    ROUND(AVG(avg_watch_time_sec), 2)
        AS avg_watch_time_sec
FROM nike_insights_2025.nike_videos
GROUP BY category
ORDER BY AVG(completion_rate) DESC, category ASC;


-- Q4. Creator Impact:
-- Top 10 creators by average views and their creator tier

SELECT
    author_handle,
    creator_tier,
    ROUND(AVG(views), 2) AS avg_views
FROM nike_insights_2025.nike_videos
GROUP BY author_handle, creator_tier
ORDER BY AVG(views) DESC, author_handle ASC
LIMIT 10;


-- Q5. Hashtag ROI:
-- Top 20 hashtags by total views and median engagement rate

WITH ranked_engagement AS (
    SELECT
        hashtag,
        views,
        engagement_rate,
        ROW_NUMBER() OVER (
            PARTITION BY hashtag
            ORDER BY engagement_rate, row_id
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY hashtag
        ) AS total_rows
    FROM nike_insights_2025.nike_videos
)
SELECT
    hashtag,
    SUM(views) AS total_views,
    ROUND(
        AVG(
            CASE
                WHEN rn IN (
                    FLOOR((total_rows + 1) / 2),
                    FLOOR((total_rows + 2) / 2)
                )
                THEN engagement_rate
            END
        ) * 100,
        2
    ) AS median_engagement_rate_pct
FROM ranked_engagement
GROUP BY hashtag
ORDER BY total_views DESC, hashtag ASC
LIMIT 20;


-- Q6. Emoji Effect:
-- Median engagement per 1,000 views with and without emojis

WITH ranked_emoji AS (
    SELECT
        has_emoji,
        engagement_per_1k,
        ROW_NUMBER() OVER (
            PARTITION BY has_emoji
            ORDER BY engagement_per_1k, row_id
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY has_emoji
        ) AS total_rows
    FROM nike_insights_2025.nike_videos
)
SELECT
    CASE
        WHEN has_emoji = 1 THEN 'With Emoji'
        ELSE 'Without Emoji'
    END AS title_type,
    ROUND(AVG(engagement_per_1k), 2)
        AS median_engagement_per_1k
FROM ranked_emoji
WHERE rn IN (
    FLOOR((total_rows + 1) / 2),
    FLOOR((total_rows + 2) / 2)
)
GROUP BY has_emoji
ORDER BY has_emoji DESC;


-- Q7. Upload Timing:
-- Average views and completion rate by day and hour

SELECT
    publish_dayofweek,
    upload_hour,
    ROUND(AVG(views), 2) AS avg_views,
    ROUND(AVG(completion_rate) * 100, 2)
        AS avg_completion_rate_pct
FROM nike_insights_2025.nike_videos
GROUP BY publish_dayofweek, upload_hour
ORDER BY
    FIELD(
        publish_dayofweek,
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
    ),
    upload_hour;
    
    
    -- Q8. Trend Momentum:
-- Median engagement velocity and trend duration by trend type

WITH ranked_trends AS (
    SELECT
        trend_type,
        engagement_velocity,
        trend_duration_days,
        ROW_NUMBER() OVER (
            PARTITION BY trend_type
            ORDER BY engagement_velocity, row_id
        ) AS velocity_rank,
        ROW_NUMBER() OVER (
            PARTITION BY trend_type
            ORDER BY trend_duration_days, row_id
        ) AS duration_rank,
        COUNT(*) OVER (
            PARTITION BY trend_type
        ) AS total_rows
    FROM nike_insights_2025.nike_videos
)
SELECT
    trend_type,
    ROUND(AVG(
        CASE
            WHEN velocity_rank IN (
                FLOOR((total_rows + 1) / 2),
                FLOOR((total_rows + 2) / 2)
            )
            THEN engagement_velocity
        END
    ), 2) AS median_engagement_velocity,
    ROUND(AVG(
        CASE
            WHEN duration_rank IN (
                FLOOR((total_rows + 1) / 2),
                FLOOR((total_rows + 2) / 2)
            )
            THEN trend_duration_days
        END
    ), 2) AS median_trend_duration_days
FROM ranked_trends
GROUP BY trend_type
ORDER BY FIELD(trend_type, 'Short', 'Medium', 'Evergreen');


-- Q9. Device Analysis:
-- Average completion rate by device type and brand

SELECT
    device_type,
    device_brand,
    ROUND(AVG(completion_rate) * 100, 2)
        AS avg_completion_rate_pct
FROM nike_insights_2025.nike_videos
GROUP BY device_type, device_brand
ORDER BY
    device_type,
    AVG(completion_rate) DESC,
    device_brand;
    
    
    -- Q10. Traffic Sources:
-- Video count and median completion rate by traffic source

WITH ranked_traffic AS (
    SELECT
        traffic_source,
        completion_rate,
        ROW_NUMBER() OVER (
            PARTITION BY traffic_source
            ORDER BY completion_rate, row_id
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY traffic_source
        ) AS total_rows
    FROM nike_insights_2025.nike_videos
)
SELECT
    traffic_source,
    COUNT(*) AS total_videos,
    ROUND(AVG(
        CASE
            WHEN rn IN (
                FLOOR((total_rows + 1) / 2),
                FLOOR((total_rows + 2) / 2)
            )
            THEN completion_rate
        END
    ) * 100, 2) AS median_completion_rate_pct
FROM ranked_traffic
GROUP BY traffic_source
ORDER BY total_videos DESC, traffic_source ASC;


-- Q11. Seasonal Insights:
-- Total views and average engagement rate by event season

SELECT
    event_season,
    SUM(views) AS total_views,
    ROUND(AVG(engagement_rate) * 100, 2)
        AS avg_engagement_rate_pct
FROM nike_insights_2025.nike_videos
GROUP BY event_season
ORDER BY total_views DESC, event_season ASC;


-- Q12. Data Quality Check:
-- Return rows with mismatched engagement totals

SELECT *
FROM nike_insights_2025.nike_videos
WHERE engagement_total <> (likes + comments + shares + saves);