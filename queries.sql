-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

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

