-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it


SET search_path TO public; 


/* ================== TABLES ================== */ 

CREATE TABLE IF NOT EXISTS users (
	user_id SERIAL PRIMARY KEY, -- auto increment unique id for each user
	user_name VARCHAR(100) NOT NULL, -- username is required
	email VARCHAR(100) UNIQUE NOT NULL CHECK (email=LOWER(email)), -- must be unique and stored in lowercase
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- set default to current_timestamp
	last_login TIMESTAMP -- allow nulls if user has never logged in
); 


CREATE TABLE IF NOT EXISTS artists (
	artist_id SERIAL PRIMARY KEY,
	artist_name VARCHAR(100) NOT NULL,
	country CHAR(2) 
); 

CREATE TABLE IF NOT EXISTS albums (
	album_id SERIAL PRIMARY KEY,
	album_name VARCHAR(100) NOT NULL,
	label VARCHAR(60),
	release_year INT CHECK (release_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE))
);

CREATE TABLE IF NOT EXISTS songs (
	song_id SERIAL PRIMARY KEY,
	album_id INT, 
	song_name VARCHAR(100) NOT NULL,
	FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE SET NULL
);  

CREATE TABLE IF NOT EXISTS song_artists (
	song_id INT NOT NULL,
	artist_id INT NOT NULL,
	PRIMARY KEY (song_id, artist_id),
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE,
	FOREIGN KEY(artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE
); 

CREATE TABLE IF NOT EXISTS playlists (
	playlist_id SERIAL PRIMARY KEY,
	user_id INT NOT NULL,
	playlist_name VARCHAR(80) NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	p_type VARCHAR(10) NOT NULL CHECK(p_type IN('public', 'private')),
	FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
	UNIQUE(user_id, playlist_name)
	
); 

CREATE TABLE IF NOT EXISTS plays ( 
	play_id SERIAL PRIMARY KEY, 
	user_id INT,
	song_id INT NOT NULL,
	played_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
	FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE 
	 
); 

CREATE TABLE IF NOT EXISTS playlist_songs (
	playlist_id INT NOT NULL,
	song_id INT NOT NULL,
	position INT NOT NULL,
	PRIMARY KEY (playlist_id, song_id),
	UNIQUE(playlist_id, position),
	FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id) ON DELETE CASCADE,
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE
	
); 



/* ================== INDEXES ================== */ 


CREATE INDEX idx_song_artist_id ON song_artists(artist_id); 

CREATE INDEX idx_plays_song_id ON plays(song_id); 

CREATE INDEX idx_playlist_songs_song_id ON playlist_songs(song_id); 





/* ================== VIEWS ================== */ 







/* ================== INSERTS ================== */ 

-- Users 
INSERT INTO users (user_name, email, last_login) VALUES
('alice', 'alice@example.com', CURRENT_TIMESTAMP),
('bob', 'bob@example.com', NULL),
('charlie', 'charlie@example.com', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('diana', 'diana@example.com', NULL);


-- Artists 
INSERT INTO artists (artist_name, country) VALUES
('Coldplay', 'UK'),
('Taylor Swift', 'USA'),
('Daft Punk', 'France'),
('Unknown Indie', NULL);


-- Albums 
INSERT INTO albums (album_name, label, release_year) VALUES
('Parachutes', 'Parlophone', 2000),
('1989', 'Big Machine', 2014),
('Random Access Memories', 'Columbia', 2013);


-- Songs 
INSERT INTO songs (album_id, song_name) VALUES
(1, 'Yellow'),
(1, 'Trouble'),
(2, 'Blank Space'),
(2, 'Style'),
(3, 'Get Lucky'),
(NULL, 'Loose Single');  


-- Song artists 
INSERT INTO song_artists (song_id, artist_id) VALUES
(1, 1), 
(2, 1),
(3, 2),
(4, 2),
(5, 3),
(6, 4); 


-- Playlists 
INSERT INTO playlists (user_id, playlist_name, p_type) VALUES
(1, 'Favorites', 'public'),
(1, 'Chill', 'private'),
(2, 'Workout', 'public'),
(3, 'Sad Songs', 'private');


-- Plays 
INSERT INTO plays (user_id, song_id, played_at) VALUES
(1, 1, CURRENT_TIMESTAMP),
(1, 3, CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(2, 5, CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(3, 2, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 1, CURRENT_TIMESTAMP - INTERVAL '2 days');


-- Playlist songs
INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES
(1, 1, 1),
(1, 3, 2),
(1, 5, 3),

(2, 2, 1),
(2, 6, 2),

(3, 5, 1),

(4, 2, 1),
(4, 4, 2);











