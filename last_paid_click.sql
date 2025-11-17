select
    s.visitor_id,
    max(s.visit_date) as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s left join sessions as s2 on s.visitor_id = s2.visitor_id
left join leads as l on s.visitor_id = l.visitor_id
group by 1, 3, 4, 5, 6, 7, 8, 9, 10
order by 8 desc nulls last, 2, 3, 4, 5;
