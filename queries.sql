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