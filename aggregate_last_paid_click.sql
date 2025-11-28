WITH visitors AS (
    SELECT
        DATE(visit_date) AS visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        COUNT(*) AS visitors_count
    FROM sessions 
    WHERE medium in ('cpc', 'cpm', 'cpa', 'youtube',
'cpp', 'tg', 'social') 
    GROUP BY 1, 2, 3, 4
),
paid_sources AS (
    SELECT DISTINCT utm_source FROM vk_ads
    UNION
    SELECT DISTINCT utm_source FROM ya_ads
),
paid_join AS (
    SELECT
        l.lead_id,
        l.amount,
        l.created_at,
        l.closing_reason,
        l.status_id,
        DATE(s.visit_date) AS visit_date,
        s.source  AS utm_source,
        s.medium  AS utm_medium,
        s.campaign AS utm_campaign,
        s.visit_date AS session_ts
    FROM leads AS l
    INNER JOIN  sessions s ON l.visitor_id =
s.visitor_id
    INNER JOIN paid_sources AS ps ON s.source = 
ps.utm_source
    WHERE s.visit_date <= l.created_at
),
last_paid AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY lead_id
                ORDER BY session_ts DESC
            ) AS rn
        FROM paid_join
    ) AS t
    WHERE rn = 1
),
leads AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(*) AS leads_count
    FROM last_paid
    GROUP BY 1, 2, 3, 4
),
purchases AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(*) AS purchases_count,
        SUM(amount) AS revenue
    FROM last_paid
    WHERE 
        closing_reason = 'Успешно реализовано'
        OR status_id = 142
    GROUP BY 1, 2, 3, 4
),
costs AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT 
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent 
        FROM vk_ads
        UNION ALL
        SELECT 
        campaign_date, 
        utm_source, 
        utm_medium, 
        utm_campaign, 
        daily_spent FROM ya_ads
    ) AS t
    GROUP BY 1, 2, 3, 4)
SELECT
    v.visit_date,
    v.visitors_count,
    v.utm_source,
    v.utm_medium,
    v.utm_campaign,
    COALESCE(c.total_cost, 0) AS total_cost,
    COALESCE(l.leads_count, 0) AS leads_count,
    COALESCE(p.purchases_count, 0) AS purchases_count,
    COALESCE(p.revenue, 0) AS revenue
FROM visitors AS v
LEFT JOIN costs AS c 
USING (visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads AS l 
USING (visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN purchases AS p 
USING (visit_date, utm_source, utm_medium, utm_campaign)
ORDER BY
    v.visit_date ASC,
    v.visitors_count DESC,
    v.utm_source ASC,
    v.utm_medium ASC,
    v.utm_campaign ASC,
    revenue DESC NULLS LAST;
