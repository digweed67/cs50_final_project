-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- =====================================
-- 1. BASIC RETRIEVAL
-- =====================================

-- 1.List all users with their usernames and email addresses.
SELECT user_name, email
FROM users;


-- 2.Show all songs along with their album names (including singles which don't belong to any albums).
SELECT song_name, album_name
FROM songs s
LEFT JOIN albums a
	ON s.album_id = a.album_id; 


-- 3.Retrieve all playlists created by user_id 3. 
SELECT playlist_id, playlist_name
FROM playlists 
WHERE user_id = 3; 


-- 4. Display all songs that do not belong to any album.
SELECT song_name
FROM songs
WHERE album_id IS NULL; 


-- 5.List all artists and their countries, including those with no country specified.
SELECT artist_name, country
FROM artists; 

-- =====================================
-- 2. FILTERING AND CONDITIONS
-- =====================================


-- 6.Find all users who have logged in within the last 2 days.
SELECT user_id, user_name, last_login
FROM users
WHERE last_login >= CURRENT_TIMESTAMP - INTERVAL '2 days'; 


-- 7.	Retrieve all playlists that are public.
SELECT playlist_id, playlist_name, user_id
FROM playlists
WHERE p_type = 'public'; 


-- 8.Show all albums released after 2010.
SELECT album_id, album_name, release_year
FROM albums 
WHERE release_year > 2010; 


-- 9.List all users who have never logged in.
SELECT user_id, user_name 
FROM users
WHERE last_login IS NULL; 


-- 10.Find all playlists created by user 1 that are private.
SELECT playlist_id, playlist_name
FROM playlists
WHERE user_id = 1 
AND p_type = 'private';


-- =====================================
-- 3. SORTING AND LIMITING
-- =====================================

-- 11.Display all songs sorted alphabetically by name.
SELECT song_id, song_name 
FROM songs 
ORDER BY song_name ASC; 


-- 12.List the 5 most recently created playlists.
SELECT playlist_id, playlist_name, created_at
FROM playlists 
ORDER BY created_at DESC
LIMIT 5; 


-- 13.Show users ordered by their last login time (most recent first).
SELECT user_id, user_name, last_login
FROM users
WHERE last_login IS NOT NULL
ORDER BY last_login DESC; 


-- =====================================
-- 4. AGGREGATIONS
-- =====================================

-- 14.Count the total number of users.
SELECT COUNT(*) 
FROM users; 


-- 15.Find how many songs exist in each album.
SELECT a.album_id, COUNT(song_id) AS song_count
FROM albums a
LEFT JOIN songs s
	ON a.album_id = s.album_id 
GROUP BY a.album_id
ORDER BY a.album_id ASC; 


-- 16.Count how many playlists each user has created.
SELECT user_id, COUNT(playlist_id) AS playlist_count
FROM playlists 
GROUP BY user_id 
ORDER BY playlist_count DESC; 


-- 17.Find the total number of plays for each song.
SELECT s.song_id, s.song_name, COUNT(p.play_id) AS play_count
FROM plays p
JOIN songs s
	ON p.song_id = s.song_id 
GROUP BY s.song_id, s.song_name 	
ORDER BY play_count DESC;


-- =====================================
-- 5. GROUPING AND HAVING
-- =====================================


-- 18.Determine the average number of plays per user.
 SELECT AVG(play_count) AS avg_plays_per_user
 FROM (
 	SELECT user_id, COUNT(*) AS play_count
 	FROM plays 
 	WHERE user_id IS NOT NULL
 	GROUP BY user_id
 ) sub; 


-- 19.List users who have created more than one playlist.
SELECT p.user_id, u.user_name, COUNT(p.playlist_id) AS playlist_count
FROM playlists p
JOIN users u
	ON p.user_id = u.user_id
GROUP BY p.user_id, u.user_name
HAVING COUNT(p.playlist_id) > 1
ORDER BY p.user_id;


-- 20.Show songs that have been played more than 5 times.
SELECT s.song_id, s.song_name, COUNT(p.play_id) AS play_count
FROM songs s
JOIN plays p
	ON s.song_id = p.song_id 
GROUP BY s.song_id, s.song_name
HAVING COUNT(p.play_id) > 5
ORDER BY s.song_id;
 

-- 21.Find albums that contain more than 2 songs.
SELECT a.album_id, a.album_name, COUNT(s.song_id) AS song_count
FROM albums a
JOIN songs s 
	ON a.album_id = s.album_id 
GROUP BY a.album_id, a.album_name
HAVING COUNT(s.song_id) > 2
ORDER BY a.album_id;

-- =====================================
-- 6. JOINS
-- =====================================

-- 22.List all songs along with the names of their artists.
SELECT a.artist_name, s.song_name
FROM songs s 
JOIN song_artists sa
	ON sa.song_id = s.song_id
JOIN artists a
	ON a.artist_id = sa.artist_id
ORDER BY a.artist_name, s.song_name; 


-- 23.Display all playlists along with the username of the creator.
SELECT u.user_name, p.playlist_name
FROM playlists p
JOIN users u
	ON p.user_id = u.user_id
ORDER BY u.user_name; 


-- 24.Show all songs in each playlist (playlist name + song name).
SELECT p.playlist_name, s.song_name
FROM playlists p
JOIN playlist_songs ps
	ON p.playlist_id = ps.playlist_id 
JOIN songs s
	ON ps.song_id = s.song_id
ORDER BY p.playlist_name, s.song_name; 


-- 25.List all plays along with the username and song name.
SELECT p.play_id, u.user_name, s.song_name
FROM plays p
JOIN users u 
	ON u.user_id = p.user_id 
JOIN songs s
	ON s.song_id = p.song_id
ORDER BY p.play_id;


-- 26.Display all artists who have songs in the database.
SELECT DISTINCT a.artist_id, a.artist_name
FROM artists a
JOIN song_artists sa 
	ON a.artist_id = sa.artist_id
ORDER BY a.artist_id;  


-- =====================================
-- 7. MULTI-TABLE LOGIC
-- =====================================
-- 27.Find all songs that appear in the playlist with id 1. 
SELECT s.song_id, s.song_name
FROM songs s
JOIN playlist_songs ps
	ON s.song_id = ps.song_id
WHERE ps.playlist_id = 1; 


-- 28.List all users who have played the song with id 4.
SELECT DISTINCT u.user_id, u.user_name
FROM users u
JOIN plays p
	ON u.user_id = p.user_id
WHERE p.song_id = 4
ORDER BY user_id;


-- 29.Show all playlists that contain songs by the artist with id 4.
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

-- 30.Find the song(s) with the highest number of plays.
SELECT song_id, COUNT(*) AS plays_count
FROM plays
GROUP BY song_id
HAVING COUNT(*) = (
    SELECT MAX(play_count)
    FROM (
        SELECT COUNT(*) AS play_count
        FROM plays
        GROUP BY song_id
    ) sub
);


-- 31.Retrieve users who have created the most playlists.
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


-- 32.Find songs that have never been played.
SELECT song_id 
FROM songs s
WHERE NOT EXISTS (SELECT 1 FROM plays p WHERE s.song_id = p.song_id );


-- 33.List playlists that contain more songs than the average playlist.
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

-- 34.List all song IDs that appear in playlists or in plays.
SELECT song_id 
FROM playlist_songs 
UNION 
SELECT song_id 
FROM plays; 


-- 35.Find songs that are in playlists but have never been played.
-- Result is none 
SELECT song_id 
FROM playlist_songs 
EXCEPT 
SELECT song_id 
FROM plays; 


-- 36.Find songs that have been played but are not in any playlist.
SELECT song_id 
FROM plays 
EXCEPT 
SELECT song_id 
FROM playlist_songs;

-- =======================================
-- 10. PATTERN MATCHING AND NULL HANDLING
-- =======================================


-- 37.Find all songs with names containing the word “Single”.
SELECT song_name
FROM songs 
WHERE LOWER(song_name) LIKE '%single%';


-- 38.Show songs where the album is missing.
SELECT song_id, song_name
FROM songs
WHERE album_id IS NULL;


-- 39.Replace NULL last_login values with a readable label like “Never logged in”.
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


-- 40.Categorize users as “Active” or “Moderate” or "Inactive" based on their number of plays.
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


-- 41.Classify songs as “Hit", "Popular” or “Unpopular” based on number of plays.
SELECT 
	s.song_id,
	s.song_name,
	COUNT(p.play_id) AS total_plays,
	CASE 
		WHEN COUNT(p.play_id) >= 50 THEN 'Hit'
		WHEN COUNT(p.play_id) >= 14 THEN 'Popular'
		ELSE 'Unpopular'
	END AS popularity
FROM songs s
LEFT JOIN plays p
	ON s.song_id = p.song_id 
GROUP BY s.song_id, s.song_name 
ORDER BY total_plays DESC; 


-- =========================================================
-- 12. COMMON TABLE EXPRESSIONS (CTEs) AND WINDOW FUNCTIONS
-- =========================================================

-- 42.Find the top 5 users by total number of song plays, and include their usernames and play counts, including ties.
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


-- 43.Show each playlist along with the total number of songs it contains and label empty playlists clearly.
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


-- 44.Find the average number of songs per playlist, then list only playlists that exceed that average.
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


-- 45.For each user, calculate their total plays and rank them from highest to lowest.
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


-- 46.List songs along with how many times they’ve been played, but only include songs above the average play count.
WITH total_plays AS (
	SELECT 
		song_id,
		COUNT(play_id) AS play_count
	FROM plays 
	GROUP BY song_id
),
avg_total_plays AS (
	SELECT 
		ROUND(AVG(play_count), 2) AS avg_play_count
	FROM total_plays
)
SELECT 
	tp.song_id,
	s.song_name,
	tp.play_count,
	a.avg_play_count
FROM songs s
JOIN total_plays tp
	ON s.song_id = tp.song_id 
CROSS JOIN avg_total_plays a
WHERE tp.play_count > a.avg_play_count
ORDER BY tp.play_count DESC; 

-- =========================================================
-- 13. VIEWS  
-- =========================================================

/*To see the views for exercises 47,48,49 and 50 
check the views section in schema. */ 

-- 47. Test view v_artist_album_song
SELECT * FROM v_artist_album_song;

-- 48. Test view v_plays_per_song 
SELECT * FROM v_plays_per_song ORDER BY play_count DESC;

-- 49. Test view v_user_playlists
SELECT * FROM v_user_playlists ORDER BY playlist_count DESC;

-- 50. Test view v_public_playlists WITH CHECK OPTION
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

SELECT * FROM playlists WHERE playlist_name = 'Summer Party';

-- we delete it using the id in case there's various playlist with the same name 
DELETE FROM playlists WHERE playlist_id = 13; 


-- =========================================================
-- 14. ADVANCED JOINS  
-- =========================================================

-- 51.List all songs along with their album, artist, and total play count in a single query.
WITH play_counts AS (
	SELECT 
		song_id,
		COUNT(*) AS play_count
	FROM plays
	GROUP BY song_id
)
SELECT
	s.song_name, 
	COALESCE(a.album_name, 'Single') AS album_name, 
	ar.artist_name,
	COALESCE(pc.play_count, 0) AS play_count
FROM songs s
LEFT JOIN albums a
	ON s.album_id = a.album_id 
JOIN song_artists sa
	ON s.song_id = sa.song_id
JOIN artists ar
	ON sa.artist_id = ar.artist_id 
LEFT JOIN play_counts pc
	ON s.song_id = pc.song_id
GROUP BY s.song_name, a.album_name, ar.artist_name, pc.play_count 
ORDER BY play_count DESC; 


-- 52.Find all users who have created playlists containing songs they have also played.
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


-- 53.Show all pairs of users who have at least one song in common across their playlists and count them.

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


-- 54.List playlists that contain songs from more than one artist.
 SELECT 
 	p.playlist_name
 FROM playlists p
 JOIN playlist_songs ps
 	ON p.playlist_id = ps.playlist_id
 JOIN song_artists sa
 	ON ps.song_id = sa.song_id
GROUP BY p.playlist_name
HAVING COUNT(DISTINCT sa.artist_id) > 1; 


-- 55.Find songs that appear in multiple playlists, along with how many playlists they appear in.
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