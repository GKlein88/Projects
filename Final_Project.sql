USE mavenfuzzyfactory;

/*
1. First, I’d like to show our volume growth. Can you pull overall session and order volume, 
trended by quarter for the life of the business? Since the most recent quarter is incomplete, 
you can decide how to handle it.
*/ 
SELECT
	year(w.created_at) as yr,
    quarter(w.created_at) as qrt,
	count(distinct w.website_session_id) as sessions,
    count(distinct o.order_id) as orders
FROM
	website_sessions w
    LEFT JOIN
		orders o ON w.website_session_id=o.website_session_id
WHERE
	w.created_at < '2015-03-20'
GROUP BY 1,2
ORDER BY 1,2
;

/*
2. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures 
since we launched, for session-to-order conversion rate, revenue per order, and revenue per session. 
*/
SELECT
	year(w.created_at) as yr,
    quarter(w.created_at) as qrt,
    count(distinct o.order_id)/count(distinct w.website_session_id) as conv_rate,
    sum(o.price_usd)/count(distinct o.order_id) as revenue_per_order,
    sum(o.price_usd)/count(distinct w.website_session_id) revenue_per_session
FROM
	website_sessions w
    LEFT JOIN
		orders o ON w.website_session_id=o.website_session_id
WHERE
	w.created_at < '2015-03-20'
GROUP BY 1,2
ORDER BY 1,2
;

/*
3. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/
SELECT
	year(w.created_at) as yr,
    quarter(w.created_at) as qrt,
    count(distinct case when w.utm_source='gsearch' and w.utm_campaign='nonbrand' then o.order_id else null end) as 'gsearch_nonbrand_conv_rate',
    count(distinct case when w.utm_source='bsearch' and w.utm_campaign='nonbrand' then o.order_id else null end) as 'bsearch_nonbrand_conv_rate',
    count(distinct case when w.utm_campaign='brand' then o.order_id else null end) as 'brand_conv_rate',
    count(distinct case when w.http_referer is not null and w.utm_source is null then o.order_id end) as 'organic_search_conv_rate',
    count(distinct case when w.http_referer is null and w.utm_source is null then o.order_id end) as 'direct_type_in_conv_rate'
FROM
	website_sessions w
	LEFT JOIN
		orders o ON w.website_session_id = o.website_session_id
WHERE
	w.created_at < '2015-03-20'
GROUP BY 1,2
ORDER BY 1,2
;

/*
4. Next, let’s show the overall session-to-order conversion rate trends for those same channels, 
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/
SELECT
	year(w.created_at) as yr,
    quarter(w.created_at) as qrt,
    count(distinct case when w.utm_source='gsearch' and w.utm_campaign='nonbrand' then o.order_id else null end)
	/ count(distinct case when w.utm_source='gsearch' and w.utm_campaign='nonbrand' then w.website_session_id else null end) as 'gsearch_nonbrand_conv_rate',
    count(distinct case when w.utm_source='bsearch' and w.utm_campaign='nonbrand' then o.order_id else null end)
	/ count(distinct case when w.utm_source='bsearch' and w.utm_campaign='nonbrand' then w.website_session_id else null end ) as 'bsearch_nonbrand_conv_rate',
    count(distinct case when w.utm_campaign='brand' then o.order_id else null end)
	/ count(distinct case when w.utm_campaign='brand' then w.website_session_id else null end) as 'brand_conv_rate',
    count(distinct case when w.http_referer is not null and w.utm_source is null then o.order_id end)
	/ count(distinct case when w.http_referer is not null and w.utm_source is null then w.website_session_id else null end) as 'organic_search_conv_rate',
    count(distinct case when w.http_referer is null and w.utm_source is null then o.order_id end)
	/ count(distinct case when w.http_referer is null and w.utm_source is null then w.website_session_id else null end) as 'direct_type_in_conv_rate'
FROM
	website_sessions w
	LEFT JOIN
		orders o ON w.website_session_id = o.website_session_id
WHERE
	w.created_at < '2015-03-20'
GROUP BY 1,2
ORDER BY 1,2
;	

/*
5. We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/
SELECT
	year(created_at) as yr,
    month(created_at) as mo,
    sum(CASE WHEN product_id=1 THEN price_usd ELSE NULL END) as mrfuzzy_revenue,
    sum(CASE WHEN product_id=1 THEN price_usd-cogs_usd ELSE NULL END) as mrfuzzy_margin,
    sum(CASE WHEN product_id=2 THEN price_usd ELSE NULL END) as lovebear_revenue,
    sum(CASE WHEN product_id=2 THEN price_usd-cogs_usd ELSE NULL END) as lovebear_margin,
    sum(CASE WHEN product_id=3 THEN price_usd ELSE NULL END) as birthdaybear_revenue,
    sum(CASE WHEN product_id=3 THEN price_usd-cogs_usd ELSE NULL END) as birthdaybear_margin,
    sum(CASE WHEN product_id=4 THEN price_usd ELSE NULL END) as minibear_revenue,
    sum(CASE WHEN product_id=4 THEN price_usd-cogs_usd ELSE NULL END) as minibear_margin,
    sum(price_usd) as total_revenue,
    sum(price_usd-cogs_usd) as total_margin
FROM 
	order_items
WHERE 
	created_at < '2015-03-20'
GROUP BY 1,2
ORDER BY 1,2
;

/*
6. Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to 
the /products page, and show how the % of those sessions clicking through another page has changed 
over time, along with a view of how conversion from /products to placing an order has improved.
*/
CREATE TEMPORARY TABLE sessions_hitting_product_page
SELECT
	yr,
    mo,
	sessions_hitting_product_page.website_session_id,
    sessions_hitting_product_page.product_page_id,
    MIN(w.website_pageview_id) as next_page_id
FROM(
	SELECT
		year(created_at) as yr,
		month(created_at) as mo,
		website_session_id,
		website_pageview_id as product_page_id
	FROM
		website_pageviews
	WHERE
		created_at < '2015-03-20'
		AND pageview_url='/products'
	) as sessions_hitting_product_page
    LEFT JOIN
		website_pageviews w
			ON w.website_session_id = sessions_hitting_product_page.website_session_id
            AND w.website_pageview_id > sessions_hitting_product_page.product_page_id
GROUP BY 3
;

SELECT
	s.yr,
    s.mo,
	count(distinct s.website_session_id) as sessions_to_product_page,
    count(distinct s.next_page_id) as clicked_to_next_page,
    count(distinct s.next_page_id) / count(distinct s.website_session_id) as clicktrough_rate,
    count(distinct o.order_id) as orders,
    count(distinct o.order_id) / count(distinct s.website_session_id) as conv_rate
FROM
	sessions_hitting_product_page s
	LEFT JOIN
		orders o 
         ON o.website_session_id = s.website_session_id
GROUP BY 1,2
ORDER BY 1,2
;

/*
7. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/
CREATE TEMPORARY TABLE primary_and_cross_products
SELECT
    A.order_id,
    A.primary_product_id,
    i.product_id as Xsell_product_id
FROM( 
	SELECT
        order_id,
		primary_product_id
	FROM
		orders
	WHERE
		created_at BETWEEN '2014-12-05' AND '2015-03-20'
	) as A
	LEFT JOIN
		order_items i ON i.order_id=A.order_id
        AND i.is_primary_item=0
;

SELECT
	primary_product_id,
	count(distinct order_id) as orders,
    count(distinct case when Xsell_product_id=1 then order_id else null end) as _Xsold_p1,
    count(distinct case when Xsell_product_id=2 then order_id else null end) as _Xsold_p2,
    count(distinct case when Xsell_product_id=3 then order_id else null end) as _Xsold_p3,
    count(distinct case when Xsell_product_id=4 then order_id else null end) as _Xsold_p4,
    count(distinct case when Xsell_product_id=1 then order_id else null end) / count(distinct order_id) as p1_xsell_rate,
    count(distinct case when Xsell_product_id=2 then order_id else null end) / count(distinct order_id) as p2_xsell_rate,
    count(distinct case when Xsell_product_id=3 then order_id else null end) / count(distinct order_id) as p3_xsell_rate,
    count(distinct case when Xsell_product_id=4 then order_id else null end) / count(distinct order_id) as p4_xsell_rate
FROM
	primary_and_cross_products
GROUP BY 1
;