-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it


SET search_path TO public; 


/* ================== TABLES ================== */ 

CREATE TABLE IF NOT EXISTS users (
	user_id SERIAL PRIMARY KEY,
	user_name VARCHAR(100) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL CHECK (email=LOWER(email)),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	last_login TIMESTAMP
); 


CREATE TABLE IF NOT EXISTS artists (
	artist_id SERIAL PRIMARY KEY,
	artist_name VARCHAR(100) NOT NULL,
	country VARCHAR(100)
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
	user_id INT NOT NULL,
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
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE SET NULL
	
); 



/* ================== INDEXES ================== */ 


CREATE INDEX idx_song_artist_id ON song_artists(artist_id); 

CREATE INDEX idx_plays_song_id ON plays(song_id); 

CREATE INDEX idx_playlist_songs_song_id ON playlist_songs(song_id); 





/* ================== VIEWS ================== */ 







/* ================== INSERTS ================== */ 








