with ap as --★休眠期間算出用。本誌申込履歴を代表カスタマー単位にし、指定期間の最新日付を取得している
(
#add
SELECT
		wkc.customer_code_master
	,	max(TO_DATE(TO_CHAR(ap.application_ymd_hms, 'YYYY-MM-DD'),'YYYY-MM-DD')) as application_ymd --本誌申込日
	,	count(*) as application_count --申込回数
FROM
		fyukolocal.application_history ap

INNER JOIN
		dm.bp_wk_customer as wkc
ON
		ap.customer_id = wkc.customer_id

WHERE
		ap.application_ymd_hms < '2018-03-31' --過去にさかのぼるにはこちらの期間を変える。
GROUP BY
		wkc.customer_code_master
)

,customer_segment16 as
(
SELECT
		customer_code_master
	,	reservation_customer_segment_1 as segment_web16
	,	reservation_customer_segment_2 as segment_continue16
	, 	reservation_customer_segment_3 as segment_frequency16
	,	reservation_customer_segment_4 as segment_web_shift_season16
FROM
		dm.bp_dm_customer_segment_history_latest
WHERE
		stay_year = '2016' --年度指定
)

,customer_segment17 as
(
SELECT
		customer_code_master
	,	reservation_customer_segment_1 as segment_web17
	,	reservation_customer_segment_2 as segment_continue17
	, 	reservation_customer_segment_3 as segment_frequency17
	,	reservation_customer_segment_4 as segment_web_shift_season17
FROM
		dm.bp_dm_customer_segment_history_latest
WHERE
		stay_year = '2017' --年度指定
)

, customer_segment18 as
(
SELECT
		customer_code_master
	,	reservation_customer_segment_1 as segment_web18
	,	reservation_customer_segment_2 as segment_continue18
	, 	reservation_customer_segment_3 as segment_frequency18
	,	reservation_customer_segment_4 as segment_web_shift_season18
FROM
		dm.bp_dm_customer_segment_history_latest
WHERE
		stay_year = '2018' --年度指定
)

, res_raw as
(
SELECT
		rh.customer_code_master
	,	rh.reservation_acceptance_id
	,	rh.reservation_acceptance_date
	,	MIN(rh.stay_date) as stay_date
	,	SUM(rh.earnings_point_total) as earnings

FROM
		dm.bp_dm_reservation_history as rh

WHERE
		rh.latest_ordinal_no = rh.ordinal_no
AND
		rh.status_marker in ('1','3')
AND
		rh.reservation_flag = '1'
AND
		rh.no_stay_flg = '0'
AND
		rh.stay_date < '2018-04-01'

GROUP BY
		rh.customer_code_master
	,	rh.reservation_acceptance_id
	,	rh.reservation_acceptance_date
)

, res_raw2 as
(
SELECT
		customer_code_master
	,	COUNT(distinct reservation_acceptance_id) as res_cnt
	,	MIN(reservation_acceptance_date) as min_reservation_acceptance_date
	,	MAX(reservation_acceptance_date) as max_reservation_acceptance_date
	,	MIN(stay_date) as min_stay_date
	,	MAX(stay_date) as max_stay_date
	,	SUM(earnings) as earnings
FROM
		res_raw
GROUP BY
		customer_code_master
)

, res_raw18 as
(
SELECT
		rh.customer_code_master
	,	rh.reservation_acceptance_id
	,	rh.reservation_acceptance_date
	,	MIN(rh.stay_date) as stay_date
	,	SUM(rh.earnings_point_total) as earnings
FROM
		dm.bp_dm_reservation_history as rh
WHERE
		rh.latest_ordinal_no = rh.ordinal_no
AND
		rh.status_marker in ('1','3')
AND
		rh.reservation_flag = '1'
AND
		rh.no_stay_flg = '0'
AND
		rh.stay_date between '2018-04-01' and '2019-03-31'
GROUP BY
		rh.customer_code_master
	,	rh.reservation_acceptance_id
	,	rh.reservation_acceptance_date
)

, res_raw3 as
(
SELECT
		customer_code_master
	,	COUNT(distinct reservation_acceptance_id) as res_cnt18
	,	MIN(reservation_acceptance_date) as min_reservation_acceptance_date18
	,	MAX(reservation_acceptance_date) as max_reservation_acceptance_date18
	,	MAX(stay_date) as max_stay_date18
	,	MIN(stay_date) as min_stay_date18
	,	SUM(earnings) as earnings18
FROM
		res_raw18
GROUP BY
		customer_code_master
)

SELECT
		mc.customer_code_master

	,	ap.application_ymd
	,	ap.application_count
	,	COALESCE(SIGN(ap.application_count),0) as application_flg

	,	seg16.segment_web16
	,	seg16.segment_continue16
	, 	seg16.segment_frequency16
	,	seg16.segment_web_shift_season16
	
	,	seg17.segment_web17
	,	seg17.segment_continue17 
	, 	seg17.segment_frequency17
	,	seg17.segment_web_shift_season17
	
	,	seg18.segment_web18
	,	seg18.segment_continue18
	, 	seg18.segment_frequency18
	,	seg18.segment_web_shift_season18

	,	COALESCE(SIGN(res_raw2.res_cnt),0) as res_cnt_flg

	,	res_raw2.min_reservation_acceptance_date
	,	res_raw2.max_reservation_acceptance_date
	,	res_raw2.min_stay_date
	,	res_raw2.max_stay_date

	,	COALESCE(res_raw3.earnings18,0) as monetary_gross_ltv18
	,	res_raw3.earnings18

	,	SIGN(res_raw3.res_cnt18) as res_cnt18_flg

	,	COALESCE(res_raw3.res_cnt18,0) as frequency18
	,	res_raw3.res_cnt18

	,	res_raw3.min_reservation_acceptance_date18
	,	res_raw3.max_reservation_acceptance_date18
	,	res_raw3.max_stay_date18
	,	res_raw3.min_stay_date18

	,	'2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date) as recency

	,	COALESCE(res_raw2.res_cnt,0) as frequency
	,	COALESCE(res_raw2.earnings,0) as monetary_gross_ltv

	,	CASE
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) <  366 THEN 5
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) <  731 THEN 4
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) < 1096 THEN 3
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) < 1826 THEN 2
			ELSE 1
		END as recency_manual

	,	CASE
			WHEN res_raw2.res_cnt >= 4 THEN 5
			WHEN res_raw2.res_cnt =  3 THEN 4
			WHEN res_raw2.res_cnt =  2 THEN 3
			WHEN res_raw2.res_cnt =  1 THEN 2
			ELSE 1
		END as frequency_manual

	,	CASE
			WHEN res_raw2.earnings >= 20000 THEN 5
			WHEN res_raw2.earnings >= 10000 THEN 4
			WHEN res_raw2.earnings >=  5000 THEN 3
			WHEN res_raw2.earnings >      0 THEN 2
			ELSE 1
		END as monetary_gross_ltv_manual

	,	CASE
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) <  366 THEN 5
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) <  731 THEN 4
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) < 1096 THEN 3
			WHEN ('2018-04-01' - COALESCE(res_raw2.max_reservation_acceptance_date, ap.application_ymd, mc.creation_date)) < 1826 THEN 2
			ELSE 1
		END
	+	CASE
			WHEN res_raw2.res_cnt >= 4 THEN 5
			WHEN res_raw2.res_cnt =  3 THEN 4
			WHEN res_raw2.res_cnt =  2 THEN 3
			WHEN res_raw2.res_cnt =  1 THEN 2
			ELSE 1
		END
	+	CASE
			WHEN res_raw2.earnings >= 20000 THEN 5
			WHEN res_raw2.earnings >= 10000 THEN 4
			WHEN res_raw2.earnings >=  5000 THEN 3
			WHEN res_raw2.earnings >      0 THEN 2
			ELSE 1
		END as rfm_manual

FROM
		dm.bp_dm_master_customer as mc

LEFT OUTER JOIN
		res_raw2
ON
		mc.customer_code_master = res_raw2.customer_code_master

LEFT OUTER JOIN
		res_raw3
ON
		mc.customer_code_master = res_raw3.customer_code_master

LEFT OUTER JOIN
		ap
ON
		mc.customer_code_master = ap.customer_code_master

LEFT OUTER JOIN
		customer_segment17 as seg17
ON
		mc.customer_code_master = seg17.customer_code_master

LEFT OUTER JOIN
		customer_segment18 as seg18
ON
		mc.customer_code_master = seg18.customer_code_master

LEFT OUTER JOIN
		customer_segment16 as seg16
ON
		mc.customer_code_master = seg16.customer_code_master

WHERE
		mc.customer_status = '0'
