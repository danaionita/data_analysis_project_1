/* Data cleansing SQL */

 --  USE reporting;
--  SELECT TEXT, LENGTH(TEXT) FROM  test_movies_metadata ;

CREATE TABLE  IF NOT EXISTS test_budget AS 
SELECT 
TEXT, 
case when locate('tt', TEXT) > 0 then mid(TEXT, locate('tt', TEXT)+2, 7) ELSE NULL END   as IMDB_ID,
cast(left( mid(TEXT, LOCATE(',', TEXT)+2), LOCATE(',', mid(TEXT, LOCATE(',', TEXT)+2))-1) AS float) AS budget,
LEFT (mid(TEXT, LOCATE('tt', TEXT)+13) , LOCATE(',', mid(TEXT, LOCATE('tt', TEXT)+13)) -1 ) AS NAME
FROM  test_movies_metadata 
WHERE case when locate('tt', TEXT) > 0 then mid(TEXT, locate('tt', TEXT)+2, 7) ELSE NULL END  REGEXP '[0-9]+'

CREATE TABLE test_genres AS 
WITH genres_all AS (
SELECT
case when locate('tt', homepage) > 0 then mid(homepage, locate('tt', homepage)+2, 7) ELSE NULL END   as IMDB_ID,
genre1 ,
genre2 ,
genre3 ,
genre4 ,
genre5 ,
genre6 ,
genre7 ,
genre8 ,
genre9
from genres
)
SELECT b.IMDB_ID,
GROUP_CONCAT(DISTINCT b.genre ORDER BY b.genre SEPARATOR ',') AS genre
FROM (
SELECT
IMDB_ID,
genre1 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre2 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre3 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre4 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre5 AS genre
FROM genres_all 
UNION
SELECT
IMDB_ID,
genre6 AS genre
FROM genres_all 
UNION
SELECT
IMDB_ID,
genre7 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre8 AS genre
FROM genres_all 
UNION 
SELECT
IMDB_ID,
genre9 AS genre
FROM genres_all 
) b
GROUP BY b.IMDB_ID

ALTER TABLE  test_links
ADD COLUMN imdb double ;

update test_links
SET imdb = CAST(imdbid AS DOUBLE);

ALTER TABLE  test_genres
ADD COLUMN imdb double ;

update test_genres
SET imdb = CAST(imdb_id AS DOUBLE);

ALTER TABLE test_budget
ADD COLUMN imdb double ;

update test_budget
SET imdb = CAST(case when imdb_id = 'p://n1o' then 0 else imdb_id  end AS DOUBLE);

CREATE INDEX i_imdb ON test_links  (imdb);

CREATE INDEX i_imdb ON  test_genres  (imdb);

CREATE INDEX i_imdb ON  test_budget (imdb);


ALTER TABLE test_links
ADD imdb double

update test_links
SET imdb = CAST(imdbid AS DOUBLE);


CREATE INDEX i_imdb ON test_links  (imdb);

CREATE INDEX i_movie ON test_ratings_small (userid, movieid);




CREATE TABLE movie_metabase
AS
SELECT * FROM movie_metabase_1
UNION
SELECT * FROM movie_metabase_2


ALTER TABLE movie_metabase
ADD COLUMN imdb_id2 VARCHAR(7) ;

UPDATE movie_metabase
SET imdb_id2 = mid(imdb_id, locate('tt', imdb_id)+2, 7) ;


ALTER TABLE movie_metabase
ADD COLUMN imdb DOUBLE ;


UPDATE movie_metabase
SET imdb = CASE WHEN imdb_ID2 = '' THEN 0 ELSE CAST(imdb_ID2 AS DOUBLE) END ;

CREATE INDEX i_imdb ON  movie_metabase  (imdb);




SELECT tl.imdb, mm.title, tg.genre,  case when mm.budget = 0 then NULL ELSE mm.budget END AS budget , trs.data_eval, trs.rating
FROM  test_links tl 
LEFT JOIN  movie_metabase mm ON tl.IMDB = mm.IMDB
LEFT JOIN
(SELECT t.movieid, cast(FROM_UNIXTIME(t.timestamp) AS DATE) data_eval, avg(t.rating) rating
FROM test_ratings_small t
--   WHERE t.movieid = 6 
GROUP BY t.movieid, cast(FROM_UNIXTIME(t.timestamp) AS DATE)
) trs ON tl.movieid = trs.movieid
LEFT JOIN  test_genres tg  ON tl.imdb   = tg.imdb
;
