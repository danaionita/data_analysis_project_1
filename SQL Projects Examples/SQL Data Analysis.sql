/* SQL Data Analysis */

USE reporting ;

/* Datasources 

SELECT mm.imdb
, mm.title
, case when CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) < '1900-01-01' then NULL ELSE CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) end AS release_date
, tg.genre
, case when mm.budget = 0 then NULL ELSE mm.budget END AS budget 
, case when mm.revenue = 0 then NULL ELSE mm.revenue  END AS revenue 
, mm.`status`
, mm.vote_average
, mm.vote_count
, trs.data_eval
, trs.rating
FROM  test_movie_metabase mm 
LEFT JOIN test_links tl   ON tl.IMDB = mm.IMDB
LEFT JOIN 
(SELECT t.movieid, cast(FROM_UNIXTIME(t.timestamp) AS DATE) data_eval, avg(t.rating) rating
FROM test_ratings_small t
--   WHERE t.movieid = 6 
GROUP BY t.movieid, cast(FROM_UNIXTIME(t.timestamp) AS DATE)
) trs ON tl.movieid = trs.movieid
LEFT JOIN  test_genres tg  ON mm.imdb   = tg.imdb
WHERE case when mm.budget = 0 then NULL ELSE mm.budget END IS NOT null
LIMIT 10;
*/
/* Budget vs revenue for movies released in a certain year */

WITH base AS (
SELECT mm.imdb
, mm.title
, case when CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) < '1900-01-01' then NULL ELSE CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) end AS release_date
, tg.genre
, case when cast(mm.budget AS DOUBLE) = 0 then NULL ELSE cast(mm.budget AS DOUBLE) END AS budget 
, case when LOCATE('.', revenue) > 0 then cast(CAST(CONCAT(SUBSTR(revenue,7,4),'-',SUBSTR(revenue,4,2),'-',SUBSTR(revenue,1,2)) AS DATE) AS DOUBLE) ELSE  CAST(revenue AS DOUBLE) END  AS revenue 
, mm.`status`
, format(sum(cast(mm.vote_average AS FLOAT) * cast(mm.vote_count AS DOUBLE))/ SUM(cast(mm.vote_count AS DOUBLE)),2) AS vote_average
, sum(cast(mm.vote_count AS INT)) AS vote_count
FROM  test_movie_metabase mm 
LEFT JOIN test_links tl   ON tl.IMDB = mm.IMDB
LEFT JOIN  test_genres tg  ON mm.imdb   = tg.imdb
--  WHERE mm.imdb > 0 and mm.imdb IN (157472, 235679 )
GROUP BY
 mm.imdb
, mm.title
, case when CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) < '1900-01-01' then NULL ELSE CAST(CONCAT(SUBSTR(mm.release_date,7,4),'-',SUBSTR(mm.release_date,4,2),'-',SUBSTR(mm.release_date,1,2)) AS DATE) end
, tg.genre
, case when cast(mm.budget AS DOUBLE) = 0 then NULL ELSE cast(mm.budget AS DOUBLE) END  
, case when LOCATE('.', revenue) > 0 then cast(CAST(CONCAT(SUBSTR(revenue,7,4),'-',SUBSTR(revenue,4,2),'-',SUBSTR(revenue,1,2)) AS DATE) AS DOUBLE) ELSE  CAST(revenue AS DOUBLE) END
, mm.`status`
)
/*
, averages AS (
SELECT
b.genre
,b.title
, SUM(b.budget) total_budget
, SUM(b.revenue) total_revenue
FROM base b
WHERE b.status = 'Released'
AND b.budget IS NOT NULL
AND b.revenue IS NOT null
GROUP BY
b.genre
,b.title
)




SELECT b.release_year
,b.total_budget
,b.total_revenue
,b.profitability
FROM (
SELECT
DATE_FORMAT(b.release_date, '%Y') AS release_year
, SUM(b.budget) total_budget
, SUM(b.revenue) total_revenue
, FORMAT(cast(SUM(b.revenue)/SUM(b.budget) AS decimal) ,2) AS profitability
FROM base b
WHERE b.status = 'Released'
AND b.budget IS NOT NULL
AND b.revenue IS NOT null
GROUP BY
DATE_FORMAT(b.release_date, '%Y')
) b
ORDER BY b.profitability desc
*/

/* Out of those titles for which e have data Old movies seem most profitable: those released in 1937, 1915, 1942, 1939, 1918 */

/*But it's woth to analyze those with budget above average. 
We are interested to see high budget movies performance, their titles and genres */
/*
SELECT a.genre
,a.title
,a.total_budget
,a.total_revenue
,format(a.total_revenue/ a.total_budget,2) AS avg_profitability
FROM averages a
WHERE a.total_budget > (SELECT AVG(total_budget) FROM averages)
ORDER BY format(a.total_revenue/ a.total_budget,2) desc,  a.total_budget DESC
*/

/* Out of Titles with available data and with highest budget most profitable are: 
Star Wars: The Force Awakens, Avatar, The Avengers, Titanic
*/

--  We would like to see most profitable genre (for genre combinations we consider same profitability to each genre mentioned)

/*
, first_genre AS (
SELECT 
b.genre
,case when LOCATE(',', RIGHT(b.genre, LENGTH(b.genre) -LENGTH(b.first_place) - 1)) = 0 then null ELSE RIGHT(b.genre, LENGTH(b.genre) - LOCATE (b.first_place, b.genre) - LENGTH(b.first_place) -1)  end  AS  second_place
,b.first_place
,b.total_budget
,b.total_revenue
FROM (
SELECT  
a.genre
, case when LOCATE(',', RIGHT(a.genre, LENGTH(a.genre) -1)) = 0 then RIGHT(a.genre, LENGTH(a.genre) -1) ELSE LEFT(RIGHT(a.genre, LENGTH(a.genre) -1), LOCATE(',', RIGHT(a.genre, length(genre) -1)) -1) end first_place
,format(SUM(a.total_budget),0) total_budget
,format(SUM(a.total_revenue),0) total_revenue
FROM averages a
WHERE a.genre > '' 
GROUP BY 
a.genre
, case when LOCATE(',', RIGHT(a.genre, LENGTH(a.genre) -1)) = 0 then RIGHT(a.genre, LENGTH(a.genre) -1) ELSE LEFT(RIGHT(a.genre, LENGTH(a.genre) -1), LOCATE(',', RIGHT(a.genre, length(genre) -1)) -1) END) b
)
, second_genre AS (
SELECT 
b.genre
,case when LOCATE(',', b.second_place) = 0 then RIGHT(b.genre, LENGTH(b.genre) - LOCATE (b.first_place, b.genre) - LENGTH(b.first_place) -1) ELSE left(b.second_place, LOCATE (',', b.second_place) -1)  end  AS  second_place
,b.first_place
,b.total_budget
,b.total_revenue
FROM (
select
b.genre
,case when LOCATE(',', b.first_place) > 0 then LEFT( b.first_place, LOCATE(',', b.first_place)-1) ELSE RIGHT(b.genre, LENGTH(b.genre) - LOCATE(b.first_place,b.genre) - LENGTH(b.first_place) -1 )END AS  second_place
,b.first_place
,b.total_budget
,b.total_revenue
FROM first_genre b
) b
)
, third_genre AS (
SELECT 
b.genre
,case when LOCATE(',', b.third_place) = 0 then RIGHT(b.genre, LENGTH(b.genre) - LENGTH(b.second_place) - LENGTH(b.first_place) -4) ELSE left(b.third_place, LOCATE (',', b.third_place) -1)  end  AS  third_place
,b.second_place
,b.first_place
,b.total_budget
,b.total_revenue
FROM (
select
b.genre
,case when LOCATE(',', right(b.genre, LENGTH(b.genre) - LENGTH(b.second_place) - LENGTH(b.first_place) -2) )  > 0 then  RIGHT(b.genre, LENGTH(b.genre) - LOCATE(b.second_place,b.genre) - LENGTH(b.second_place) -1 ) ELSE  RIGHT(b.genre, LENGTH(b.genre) - LENGTH(b.first_place) - LENGTH(b.second_place) -3) END AS  third_place
,b.second_place
,b.first_place
,b.total_budget
,b.total_revenue
FROM second_genre b
) b
)
, base1 AS (
SELECT
b1.place
,sum(b1.mentions) mentions
,sum(b1.total_budget) total_budget
,sum(b1.total_revenue) total_revenue
FROM (
SELECT 
trim(b.place) place,
COUNT(trim(b.place) ) mentions,
sum(b.total_budget) total_budget,
SUM(b.total_revenue) total_revenue 
FROM (
SELECT 
t.first_place AS place,
t.total_budget,
t.total_revenue
from third_genre t


UNION

SELECT 
trim(t.second_place) AS place,
t.total_budget,
t.total_revenue
from third_genre t


union



SELECT 
trim(t.third_place) AS place,
t.total_budget,
t.total_revenue
from third_genre t
) b
WHERE place > ''
GROUP BY b.place
) b1
GROUP BY b1.place
)

SELECT
b.place
,b.mentions
,b.total_budget
,FORMAT(b.total_revenue /b.total_budget ,2) profitability
FROM base1 b
ORDER BY b.mentions DESC, FORMAT(b.total_revenue /b.total_budget ,2) DESC, b.total_budget DESC

*/

/* Drama is most profitable, followed by Comedy and Adventure */

/*   Title rankings by  vote average, vote count, profitability   */


/*
SELECT
b.title
,b.budget
,b.revenue
,b.vote_average
,b.vote_count
FROM (
SELECT
title
,sum(budget) budget
,sum(revenue) revenue
,avg(vote_average) vote_average
,sum(vote_count) vote_count
,ROW_NUMBER () OVER (ORDER BY vote_count DESC, vote_average DESC, revenue/budget DESC, budget DESC ) nb
FROM base
WHERE title > ''
AND budget IS NOT NULL
GROUP BY 
title
) b
WHERE b.nb < 11
ORDER BY b.nb asc
*/
/* best performance in terms of vore average and profitability: Inception, The Dark Knight, The Avengers, Avatar, 
Deadpool, Interstellar
*/

/* we are interested in budget comparison between different title statuses */


SELECT
status
,sum(budget) budget
,format(AVG(vote_average),2)vote_average
,SUM(vote_count) vote_count
FROM base
WHERE STATUS > '' AND STATUS NOT LIKE '%iso_%'
GROUP BY
status
ORDER BY sum(budget) desc

/* Highest in budget, vote_average, vote_count are Released, Post Production and Rumored */