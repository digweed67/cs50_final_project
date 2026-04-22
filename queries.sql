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


