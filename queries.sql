-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- =====================================
-- 1. BASIC RETRIEVAL
-- =====================================

-- 1.List all users with their usernames and email addresses.
SELECT user_name, email
FROM users;


-- 2.Show all songs along with their album names (including singles which don't belong to any albums).
-- We use the view created for it, we coalesce songs with no album to "Single"
SELECT song_name, album_name 
FROM v_songs_clean;


-- 3. Display all songs that do not belong to any album.
-- IS NULL is used to find songs with no album_id 
SELECT song_name
FROM songs
WHERE album_id IS NULL; 


-- 4.List all artists and their countries, including those with no country specified.
SELECT artist_name, country
FROM artists; 



-- =====================================
-- 2. FILTERING AND CONDITIONS
-- =====================================

-- 5.Find all users who have logged in within the last 2 days.
-- CURRENT_TIMESTAMP AND INTERVAL filter users who have logged in within the rolling 48h window.
SELECT user_id, user_name, last_login
FROM users
WHERE last_login >= CURRENT_TIMESTAMP - INTERVAL '2 days'; 


-- 6.	Retrieve all playlists that are public.
SELECT playlist_id, playlist_name, user_id
FROM playlists
WHERE p_type = 'public'; 


-- 7.Show all albums released after 2010.
SELECT album_id, album_name, release_year
FROM albums 
WHERE release_year > 2010; 


-- 8.List all users who have never logged in.
SELECT user_id, user_name 
FROM users
WHERE last_login IS NULL; 


-- =====================================
-- 3. SORTING AND LIMITING
-- ===================================== 


-- 9.List the 5 most recently created playlists.
-- We use a secondary sort (playlist_id) to make sure results are deterministic if there's a tie
SELECT playlist_id, playlist_name, created_at
FROM playlists 
ORDER BY created_at DESC, playlist_id DESC
LIMIT 5;  


-- =====================================
-- 4. AGGREGATIONS
-- ===================================== 

-- 10.Find how many songs exist in each album.
-- Left join includes album with no matching songs (null) 
-- count(song_id) counts non null values, so albums with no matching songs return 0.
SELECT a.album_id, a.album_name, COUNT(song_id) AS song_count
FROM albums a
LEFT JOIN songs s
	ON a.album_id = s.album_id 
GROUP BY a.album_id, a.album_name
ORDER BY a.album_id ASC;  


-- 11.Find the total number of plays for each song, with at least 1 play.
-- Only includes songs that have at least one play record (filters the left join from original view)
SELECT *
FROM v_plays_per_song
WHERE play_count > 0
ORDER BY play_count DESC;



-- =====================================
-- 5. GROUPING AND HAVING
-- =====================================

-- 12.Show songs that have been played more than 5 times.
-- having filters aggregated results from the play count and select those higher than 5
SELECT song_id, song_name, play_count
FROM v_plays_per_song
WHERE play_count > 5
ORDER BY song_id;
 

-- 13.Find albums release after 2000 and with more than 2 songs.
-- Where filters only the albums released after 2000 first, before grouping.
-- After grouping, having filters those albums released after 2000 that have >2 songs. 
SELECT a.album_id, a.album_name, COUNT(s.song_id) AS song_count
FROM albums a
JOIN songs s 
	ON a.album_id = s.album_id 
WHERE a.release_year > 2000
GROUP BY a.album_id, a.album_name
HAVING COUNT(s.song_id) > 2
ORDER BY a.album_id;



-- =====================================
-- 6. JOINS
-- =====================================

-- 14.List all songs along with the names of their artists.
-- We use the view we've created for it
SELECT artists, song_name 
FROM v_songs_clean
ORDER BY artists, song_name;


-- 15.Display all playlists along with the username of the creator.
-- Joins playlists to users showing a one-to-many relationship (one user can create many playlists)
SELECT u.user_name, p.playlist_name
FROM playlists p
JOIN users u
	ON p.user_id = u.user_id
ORDER BY u.user_name; 


-- 16.Show all songs in each playlist (playlist name + song name).
-- Uses playlist_songs junction table to link playlists and songs.
-- Demonstrates a many-to-many relationship between playlists and songs.
SELECT p.playlist_name, s.song_name
FROM playlists p
JOIN playlist_songs ps
	ON p.playlist_id = ps.playlist_id 
JOIN songs s
	ON ps.song_id = s.song_id
ORDER BY p.playlist_name, s.song_name; 


-- 17.List all songs along with their total number of plays (including songs that have never been played).
-- Re-written to use the view(uses a left join to include songs with zero plays)
SELECT *
FROM v_plays_per_song
ORDER BY play_count DESC;


-- 18.Display all artists who have songs in the database.
-- Inner join includes only artists with songs
-- Song artists is a junction table which will have many duplicates for artists with many songs
-- So we use DISTINCT to remove duplicates 
SELECT DISTINCT a.artist_id, a.artist_name
FROM artists a
JOIN song_artists sa 
	ON a.artist_id = sa.artist_id
ORDER BY a.artist_id;  


-- =====================================
-- 7. MULTI-TABLE LOGIC
-- =====================================
-- 19.Find all songs that appear in the playlist with id 1. 
SELECT s.song_id, s.song_name
FROM songs s
JOIN playlist_songs ps
	ON s.song_id = ps.song_id
WHERE ps.playlist_id = 1; 


-- 20.List all users who have played the song with id 4.
-- A user can have many plays for the same song, so join produces duplicates 
-- We use distinct to return each user only once  
SELECT DISTINCT u.user_id, u.user_name
FROM users u
JOIN plays p
	ON u.user_id = p.user_id
WHERE p.song_id = 4
ORDER BY user_id;


-- 21.Show all playlists that contain songs by the artist with id 4.
SELECT DISTINCT p.playlist_id, p.playlist_name 
FROM playlists p
JOIN playlist_songs ps
	ON p.playlist_id = ps.playlist_id
JOIN song_artists sa 
	ON sa.song_id = ps.song_id
WHERE sa.artist_id = 4
ORDER BY p.playlist_id; 



-- =====================================
-- 8. SUBQUERIES
-- =====================================

-- 22.Retrieve users who have created the most playlists.
-- The inner query (derived table) produces a temporary table  with user id and playlist count 
-- MAX(playlist_count) returns highest count as a single scalar value (the max value out of playlist count)
-- Outer query groups playlists by user and filters those whose count matches the maximum.
-- Demonstrates nested subquery logic  
SELECT user_id, COUNT(*) AS playlist_count
FROM playlists 
GROUP BY user_id
HAVING COUNT(*) = (
	SELECT MAX(playlist_count)
		FROM (
			SELECT user_id, COUNT(*) AS playlist_count
			FROM playlists 
			GROUP BY user_id
		) sub
);


-- 23.Find songs that have never been played.
-- NOT EXISTS checks whether a matching play row exists for each song.
-- Unlike NOT IN which relies on comparison, it handles NULLs safely.
-- Songs are returned only when no matching song_id exists in plays.
SELECT song_id, song_name 
FROM songs s
WHERE NOT EXISTS (SELECT 1 FROM plays p WHERE s.song_id = p.song_id );


-- 24.List playlists that contain more songs than the average playlist.
-- The derived table produces a temporary table  with song count per playlist
-- AVG(song_count) returns the average count of songs across all playlists.
-- Outer query groups playlists_id and counts songs again, filtering only those above average
-- Demonstrates nested subquery logic 
SELECT playlist_id, COUNT(*) AS song_count
FROM playlist_songs
GROUP BY playlist_id
HAVING COUNT(*) > (
	SELECT AVG(song_count) AS avg_song_count
	FROM (
		SELECT COUNT(*) AS song_count
		FROM playlist_songs
		GROUP BY playlist_id) sub
);



-- =====================================
-- 9. SET OPERATIONS
-- =====================================

-- 25.List all song IDs that appear in playlists or in plays.
-- UNION combines song_ids from both queries into a single result set.
-- Duplicate song_ids appearing in both tables are automatically removed.
SELECT song_id 
FROM playlist_songs 
UNION 
SELECT song_id 
FROM plays; 


-- 26.Find songs that are in playlists but have never been played. 
-- EXCEPT returns song_ids from the first query that do not appear in the second query.
SELECT song_id 
FROM playlist_songs 
EXCEPT 
SELECT song_id 
FROM plays; 



-- =======================================
-- 10. PATTERN MATCHING AND NULL HANDLING
-- =======================================

-- 27.Find all songs with names containing the word “Single”.
-- Lower makes the comparison case sensitive 
-- LIke with % matches any characters before or after the word "single".
SELECT song_name
FROM songs 
WHERE LOWER(song_name) LIKE '%single%';


-- 28.Show songs where the album is missing.
-- Filters the rows where album_id is NULL.
-- IS NULL is the right way to compare NULLS because = NULL evaluates to UNKNOWN.
SELECT song_id, song_name
FROM songs
WHERE album_id IS NULL;


-- 29.Replace NULL last_login values with a readable label like “Never logged in”.
-- TO_CHAR converts the timestamp into text using the specified format.
-- This allows COALESCE to replace NULL values with the string 'Never logged in' (coalesce requires compatible data types).
SELECT 
	user_name, 
	COALESCE(
		TO_CHAR(last_login, 'YYYY-MM-DD HH24:MI:SS'),
		'Never logged in'
	)
FROM users;



-- =====================================
-- 11. CASE / CONDITIONAL LOGIC
-- =====================================

-- 30.Categorize users as “Active” or “Moderate” or "Inactive" based on their number of plays.
-- Counts total plays per user and classifies users based on activity level.
-- LEFT JOIN ensures users with zero plays are included in the result.
-- CASE assigns labels based on aggregated results.
SELECT 
	u.user_id,
	u.user_name,
	COUNT(p.play_id) AS total_plays,
	CASE 
		WHEN COUNT(p.play_id) >= 20 THEN 'Active'
		WHEN COUNT(p.play_id) BETWEEN 10 AND 19 THEN 'Moderate'
		ELSE 'Inactive'
	END AS activity_level
FROM users u
LEFT JOIN plays p 
	ON u.user_id = p.user_id
GROUP BY u.user_id, u.user_name
ORDER BY total_plays DESC; 

 

-- =========================================================
-- 12. COMMON TABLE EXPRESSIONS (CTEs) AND WINDOW FUNCTIONS
-- =========================================================

-- 31.Find the top 5 users by total number of song plays, and include their usernames and play counts, including ties.
-- First CTE calculates total plays per user.
-- Second CTE applies DENSE_RANK to assign rankings based on play count (ties share the same rank).
-- Final query joins users to ranked results and returns the top 5 ranks, including ties.
WITH total_plays AS (
	SELECT 	
		user_id, 
		COUNT(*) AS play_count
	FROM plays 
	GROUP BY user_id 
), 
ranked AS (
	SELECT *, 
			DENSE_RANK() OVER(ORDER BY play_count DESC) AS rnk
	FROM total_plays
)

SELECT u.user_name, r.play_count, r.rnk
FROM users u
JOIN ranked r 
	ON u.user_id = r.user_id
WHERE r.rnk <= 5
ORDER BY r.play_count DESC;


-- 32.Show each playlist along with the total number of songs it contains and label empty playlists clearly.
-- First CTE counts how many songs are in each playlist.
-- LEFT JOIN ensures playlists with no songs are still included.
-- COALESCE converts NULL counts into 0 for empty playlists.
-- We need coalesce here because aggregation in the cte happens before the left join.
-- CASE labels playlists as either "Empty playlist" or "Contains songs".
WITH total_songs AS (
	SELECT 
		playlist_id, 
		COUNT(song_id) AS song_count
	FROM playlist_songs 
	GROUP BY playlist_id 
)

SELECT 
	p.playlist_name,
	p.playlist_id,
	COALESCE(ts.song_count, 0) AS song_count,
	CASE 
		WHEN ts.song_count IS NULL THEN 'Empty playlist'
		ELSE 'Contains songs'
	END AS status
FROM playlists p 
LEFT JOIN total_songs ts
	ON p.playlist_id = ts.playlist_id 
ORDER BY song_count DESC;


-- 33.Find the average number of songs per playlist, then list only playlists that exceed that average.
-- First CTE calculates the number of songs in each playlist.
-- Second CTE calculates the average playlist size across all playlists.
-- CROSS JOIN is used to make the average value available to every row.
-- Final query returns only playlists whose song count is above the overall average.
WITH number_of_songs AS (
	SELECT 
		playlist_id,
		COUNT(song_id) AS song_count
	FROM playlist_songs 
	GROUP BY playlist_id 
),
avg_songs AS (
	SELECT 
		ROUND(AVG(song_count),2) AS avg_song_count
	FROM number_of_songs
)

SELECT  
	ns.playlist_id, 
	p.playlist_name, 
	ns.song_count 
FROM playlists p
JOIN number_of_songs ns 
	ON p.playlist_id  = ns.playlist_id
CROSS JOIN avg_songs a
WHERE ns.song_count > a.avg_song_count; 


-- 34.For each user, calculate their total plays and rank them from highest to lowest.
-- First, the CTE `total_plays` aggregates the total number of plays per user.
-- Then, the main query joins all users with the aggregated play counts.
-- LEFT JOIN ensures users with zero plays are included.
-- COALESCE(tp.play_count, 0) replaces NULLs from users with no plays with 0.
-- DENSE_RANK() window function ranks users by total plays in descending order.
-- Users with the same play count receive the same rank, no gaps.
WITH total_plays AS (
	SELECT 
		user_id, 
		COUNT(play_id) AS play_count
	FROM plays 
	GROUP BY user_id
)
SELECT 
	tp.user_id,
	u.user_name,
	COALESCE(tp.play_count, 0) AS play_count,
	DENSE_RANK () OVER (ORDER BY COALESCE(tp.play_count, 0) DESC) AS rnk
FROM users u
LEFT JOIN total_plays tp
	ON u.user_id = tp.user_id;


-- 35.List songs along with how many times they’ve been played, but only include songs above the average play count.
-- avg_total_plays CTE calculates the average play count, only including songs with plays.
-- CROSS JOIN brings the average into each row, and WHERE filters songs above that average.
WITH avg_total_plays AS (
    SELECT 
        ROUND(AVG(play_count), 2) AS avg_play_count
    FROM v_plays_per_song
    WHERE play_count > 0
)
SELECT 
    v.song_id,
    v.song_name,
    v.play_count,
    a.avg_play_count
FROM v_plays_per_song v
CROSS JOIN avg_total_plays a
WHERE v.play_count > a.avg_play_count
ORDER BY v.play_count DESC;



-- =========================================================
-- 13. VIEWS  
-- =========================================================

/*To see the views for exercises 36, 37, 38 and 39 
check the views section in schema. */ 

-- 36.Test view v_artist_album_song
SELECT * FROM v_artist_album_song;-- returns 24 rows (duplicated song because is by 2 artists)
SELECT * FROM v_songs_clean;-- returns 23 rows (deduplicated songs)

-- 37.Test view v_plays_per_song 
SELECT * FROM v_plays_per_song ORDER BY play_count DESC;

-- 38.Test view v_user_playlists
SELECT * FROM v_user_playlists ORDER BY playlist_count DESC;

-- 39.Test insert on view v_public_playlists WITH CHECK OPTION
INSERT INTO v_public_playlists (
    user_id,
    playlist_name,
    created_at,
    p_type
)
VALUES (
    3,
    'Summer Party',
    CURRENT_TIMESTAMP,
    'public'
);

-- Verify it worked:
SELECT * FROM playlists WHERE playlist_name = 'Summer Party';

-- Cleanup test inserted data: 
DELETE FROM playlists WHERE playlist_id = 13; 


-- =========================================================
-- 14. ADVANCED JOINS  
-- =========================================================

-- 40.List all songs along with their album, artist, and total play count in a single query.
-- LEFT JOIN to play_counts ensures songs with no plays are included.
-- COALESCE handles NULLs from LEFT JOINs:
--   - missing album → 'Single'
--   - missing play count → 0
SELECT
    vsc.song_name,
    vsc.album_name,
    vsc.artists,
    COALESCE(vps.play_count, 0) AS play_count
FROM v_songs_clean vsc
LEFT JOIN v_plays_per_song vps
    ON vsc.song_id = vps.song_id
ORDER BY play_count DESC;


-- 41.Find all users who have created playlists containing songs they have also played.
-- Uses EXISTS to check for at least one matching case per user.
-- Subquery joins playlists → playlist_songs → plays to find overlap between:
-- songs in user's playlists and songs the same user has played
SELECT 
    u.user_id,
    u.user_name
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM playlists p
    JOIN playlist_songs ps
        ON ps.playlist_id = p.playlist_id
    JOIN plays pl
        ON pl.song_id = ps.song_id
    WHERE p.user_id = u.user_id
      AND pl.user_id = u.user_id
);


-- 42.Show all pairs of users who have at least one song in common across their playlists and count them.
-- CTE users_songs turns playlists into a users and songs table.
-- Self-join compares the table to itself to find shared songs between users.
-- a.user_id < b.user_id prevents duplicate pairs and self-matching.
-- COUNT(*) returns the number of shared songs between each pair of users.
WITH users_songs AS (
	SELECT 
		p.user_id,
		ps.song_id
	FROM playlists p
	JOIN playlist_songs ps
		ON p.playlist_id = ps.playlist_id
)

SELECT 
	a.user_id AS user_a,
	b.user_id AS user_b,
	COUNT(*) AS matching_song_count
FROM users_songs a 
JOIN users_songs b 
	ON a.song_id = b.song_id 
	AND a.user_id < b.user_id
GROUP BY a.user_id, b.user_id; 


-- 43.List playlists that contain songs from more than one artist.
-- Join playlists → playlist_songs → song_artists to link playlists with artists.
-- HAVING filters playlists that include songs from multiple artists.
 SELECT 
 	p.playlist_name
 FROM playlists p
 JOIN playlist_songs ps
 	ON p.playlist_id = ps.playlist_id
 JOIN song_artists sa
 	ON ps.song_id = sa.song_id
GROUP BY p.playlist_name
HAVING COUNT(DISTINCT sa.artist_id) > 1; 


-- 44.Find songs that appear in multiple playlists, along with how many playlists they appear in.
-- Joins playlist_songs with songs to get song details.
-- COUNT(DISTINCT playlist_id) counts how many different playlists each song appears in.
-- HAVING filters only songs that appear in more than one playlist.
SELECT
	s.song_id,
	s.song_name,
	COUNT(DISTINCT playlist_id) AS playlist_count 
FROM playlist_songs ps
JOIN songs s
	ON s.song_id = ps.song_id
GROUP BY s.song_id, s.song_name 
HAVING COUNT(DISTINCT playlist_id) > 1
ORDER BY playlist_count DESC; 



-- =========================================================
-- 15. SECURITY & GRANTS   
-- =========================================================

-- 45.Create a read-only role that can only view songs, artists, and albums but cannot modify any data.
-- plaintext passwords are used for simplicity.
-- Real applications should hash passwords and restrict access.
DROP ROLE IF EXISTS read_only;
DROP USER IF EXISTS alice;

CREATE ROLE read_only; 

GRANT USAGE ON SCHEMA public TO read_only;

GRANT SELECT ON TABLE songs, artists, albums TO read_only;

CREATE USER alice WITH PASSWORD 'alice_pass';

GRANT read_only TO alice; 

-- Test to see if grants work as intended: 
SET ROLE alice; 
-- This works as user alice has read permissions: 
SELECT * FROM songs; 

-- This doesn't work because she doesn't have insert permissions 
-- we get: ERROR: permission denied for table songs. 
INSERT INTO songs (album_id, song_name)
VALUES (NULL, 'First Single');

RESET ROLE;
-- 46.Grant a specific user permission to insert plays but not delete them.
CREATE ROLE insert_plays;

GRANT USAGE ON SCHEMA public TO insert_plays;
-- it wasn't allowing us to access nextval() so we need to grant usage
GRANT USAGE, SELECT ON SEQUENCE plays_play_id_seq TO insert_plays;
GRANT INSERT ON TABLE public.plays TO insert_plays;

CREATE USER admin WITH PASSWORD 'admin_pass';

GRANT insert_plays TO admin; 

-- We test if the grant permission works by setting the role to admin:
SET ROLE admin;

-- The insert succeeds:
INSERT INTO public.plays (user_id, song_id)
VALUES (1, 1);

-- This fails (ERROR: permission denied for table plays):
SELECT * FROM plays; 

-- we reset back to super role
RESET ROLE;
-- we find the play id for the inserted row to delete it 
SELECT * FROM plays ORDER BY played_at DESC;

DELETE FROM plays 
WHERE play_id = 186; 



-- =========================================================
-- 16. TRANSACTIONS & ISOLATION   
-- =========================================================

-- 47.Simulate creating a playlist and adding songs to it, ensuring that if any insert fails, nothing is saved.
BEGIN; 

-- create a new playlist and return its id 
WITH new_playlist AS(
INSERT INTO playlists (user_id, playlist_name, p_type)
VALUES(1, 'Meditation Tunes', 'public')
RETURNING playlist_id
)


-- ERROR: insert fails because song 999999 doesn't exist
INSERT INTO playlist_songs (playlist_id, song_id, position)
SELECT playlist_id, 999999, 1 FROM new_playlist;

COMMIT; -- doesn't succeed because transaction has been aborted 

-- Try to select something now and this happens:
-- ERROR: current transaction is aborted, commands ignored until end of transaction block
SELECT * FROM playlists WHERE playlist_name = 'Meditation Tunes';

-- So I need to reset/rollback this transaction:
ROLLBACK; 

-- Now I try to re-run the select:
SELECT * FROM playlists WHERE playlist_name = 'Meditation Tunes';
-- And the playlist was never commited, so it does not exist  


-- Correct transaction:
BEGIN; 

-- create a new playlist and return its id 
WITH new_playlist AS(
INSERT INTO playlists (user_id, playlist_name, p_type)
VALUES(1, 'Meditation Tunes', 'public')
RETURNING playlist_id
)
-- insert the new playlist and add songs into playlist songs 
INSERT INTO playlist_songs (playlist_id, song_id, position)
SELECT playlist_id, 10, 1 FROM new_playlist;


COMMIT; -- this does run now 

-- Check the playlist and songs exist: 
SELECT * FROM playlists WHERE playlist_name = 'Meditation Tunes';

SELECT ps.*
FROM playlist_songs ps
JOIN playlists p ON p.playlist_id = ps.playlist_id
WHERE p.playlist_name = 'Meditation Tunes';

-- Delete this new data:
DELETE FROM playlists WHERE playlist_name = 'Meditation Tunes';
-- the delete from playlist_songs happens automatically due to on delete cascade 



-- 48.Update a playlist name and log the change, then roll back the transaction and verify the log behavior.

BEGIN; 

-- this should fire the trigger update playlist
UPDATE playlists 
SET playlist_name = 'New Name'
WHERE playlist_id = 1; 

ROLLBACK; -- the log won't happen due to rollback and atomicity



-- 49.Delete a song and observe how related records behave across all tables inside a transaction before committing.
BEGIN; 


DELETE FROM songs WHERE song_id = 4; 

-- We run this before rollback/committing and the song has been deleted: 
SELECT * FROM songs WHERE song_id = 4;

SELECT * FROM playlist_songs WHERE song_id = 4;

-- now we run the rollback

ROLLBACK; 

-- we run the select statements again to make sure song_id 4 is still there and it is
SELECT * FROM songs WHERE song_id = 4;

SELECT * FROM playlist_songs WHERE song_id = 4;
 


-- =========================================================
-- 17. TEST TRIGGERS   
-- =========================================================


-- 50. Test the "create playlist" trigger.

INSERT INTO playlists (user_id, playlist_name, p_type)
VALUES (2, 'My Daily Mix', 'public'); 

SELECT * FROM playlists WHERE playlist_name = 'My Daily Mix' AND user_id = 2; 
SELECT * FROM user_logs; 


-- 51. Test the "rename playlist" trigger.
UPDATE playlists
SET playlist_name = 'My Monthly Mix'
WHERE playlist_name = 'My Daily Mix'
	AND user_id = 2; 

SELECT * FROM playlists WHERE playlist_name = 'My Monthly Mix' AND user_id = 2; 
SELECT * FROM user_logs;


-- 52. Test the "delete playlist" trigger.
DELETE FROM playlists 
WHERE playlist_name = 'My Monthly Mix' 
	AND user_id = 2;

SELECT * FROM playlists WHERE playlist_name = 'My Monthly Mix' AND user_id = 2; 
SELECT * FROM user_logs;


-- 53. Test the "add song to playlist" trigger.

INSERT INTO playlist_songs (playlist_id, song_id, position)
VALUES (1, 2, 4);

SELECT * FROM user_logs;
SELECT * FROM playlist_songs WHERE playlist_id = 1;

-- 54. Test the "delete song from playlist" trigger. 
DELETE FROM playlist_songs 
WHERE playlist_id = 1
	AND song_id = 2; 

SELECT * FROM user_logs;
SELECT * FROM playlist_songs WHERE playlist_id = 1;



-- =========================================================
-- 18. ADVANCED ANALYTICS QUERIES   
-- =========================================================

-- 55.Find the song with the highest play count within each album.
-- Uses DENSE_RANK so ties are included.
WITH song_count AS (
	SELECT 
        vps.song_id,
        vps.song_name,
        vps.play_count,
        s.album_id
    FROM v_plays_per_song vps
    JOIN songs s
        ON vps.song_id = s.song_id
),

ranked_songs AS (
	SELECT
		a.album_name,
		sc.song_name,
		sc.play_count,
		DENSE_RANK() OVER (PARTITION BY a.album_id ORDER BY sc.play_count DESC) rnk
	FROM song_count sc
	JOIN albums a
		ON sc.album_id = a.album_id
)

SELECT 
	album_name,
	song_name,
	play_count
FROM ranked_songs
WHERE rnk = 1; 


-- 56.Return users who have listened to songs belonging to exactly one artist only.
-- Uses DISTINCT songs per user and counts distinct artists.

WITH user_songs AS (
	SELECT DISTINCT 
		user_id, 
		song_id
	FROM plays
),
users_artists AS (
	SELECT 
		us.*,
		a.artist_id,
		a.artist_name
	FROM user_songs us
	JOIN song_artists sa
		ON us.song_id = sa.song_id
	JOIN artists a 
		ON sa.artist_id = a.artist_id
)

SELECT 
	ua.user_id,
	MAX(ua.artist_name) AS artist_name
FROM users_artists ua 
GROUP BY user_id 
HAVING COUNT(DISTINCT ua.artist_id) = 1; 


-- 57.Find the playlist with the highest number of distinct artists
-- Counts unique artists per playlist and ranks them.
WITH playlist_artists AS (
	SELECT 
		p.playlist_id,
		COUNT(DISTINCT a.artist_id) AS artist_count
	FROM playlist_songs p 
	JOIN song_artists sa 
		ON p.song_id = sa.song_id 
	JOIN artists a 
		ON sa.artist_id = a.artist_id
	GROUP BY p.playlist_id
),

ranked_playlist_artists AS (
	SELECT 
		pa.*,
		RANK() OVER(ORDER BY pa.artist_count DESC) AS rnk
	FROM playlist_artists pa
)

SELECT  
	p.playlist_name,
	rp.artist_count 
FROM playlists p
JOIN ranked_playlist_artists rp
	ON p.playlist_id = rp.playlist_id
WHERE rnk = 1; 


-- 58.Rank albums by total number of plays of their songs
-- Uses play counts from the v_plays_per_song view.
WITH album_plays AS (
    SELECT
        s.album_id,
        SUM(vps.play_count) AS play_count
    FROM v_plays_per_song vps
    JOIN songs s
        ON s.song_id = vps.song_id
    GROUP BY s.album_id
)
SELECT
    a.album_name,
    ap.play_count,
    RANK() OVER (ORDER BY ap.play_count DESC) AS rnk
FROM album_plays ap
JOIN albums a
    ON a.album_id = ap.album_id;	
