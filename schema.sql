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
	artist_name VARCHAR(100) NOT NULL, -- required name
	country CHAR(2) -- ISO country code, allows consistent grouping
); 

CREATE TABLE IF NOT EXISTS albums (
	album_id SERIAL PRIMARY KEY,
	album_name VARCHAR(100) NOT NULL, -- album name required
	label VARCHAR(60),
	release_year INT CHECK (release_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)) -- Must be a valid year up to current date year
);

CREATE TABLE IF NOT EXISTS songs (
	song_id SERIAL PRIMARY KEY,
	album_id INT, -- allow null album ids for singles
	song_name VARCHAR(100) NOT NULL, -- song name required
	FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE SET NULL
);  

CREATE TABLE IF NOT EXISTS song_artists (
	song_id INT NOT NULL,
	artist_id INT NOT NULL,
	PRIMARY KEY (song_id, artist_id),
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE,
	FOREIGN KEY(artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE
	/* this is a joint table to reflect the many to many relationship 
	 * between songs and artists. ON DELETE CASCADE is appropriate 
	 * because each row depends entirely on both parents. 
	 * If a song or artist is removed the relationship row becomes 
	 * invalid and should be removed. 
	 */
); 

CREATE TABLE IF NOT EXISTS playlists (
	playlist_id SERIAL PRIMARY KEY,
	user_id INT NOT NULL, -- required
	playlist_name VARCHAR(80) NOT NULL, -- required
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	p_type VARCHAR(10) NOT NULL CHECK(p_type IN('public', 'private')), -- type of playlist has to be private or public
	FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE, -- if a user is deleted, their playlists are automatically deleted too
	UNIQUE(user_id, playlist_name) -- ensures a user can't have two playlists with the same name
	
); 

CREATE TABLE IF NOT EXISTS plays ( 
	play_id SERIAL PRIMARY KEY, 
	user_id INT,
	song_id INT NOT NULL,
	played_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
	FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL, -- if the user is deleted, preserve play record but remove user association
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE -- if the song is deleted then delete its plays
	 
); 

CREATE TABLE IF NOT EXISTS playlist_songs (
	playlist_id INT NOT NULL,
	song_id INT NOT NULL,
	position INT NOT NULL,
	PRIMARY KEY (playlist_id, song_id),
	UNIQUE(playlist_id, position), -- position is unique per playlist
	FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id) ON DELETE CASCADE,
	FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE
	/* if the playlist or song are deleted in the parent table, then corresponding
	 * rows are removed from this table via on delete cascade 
	 */
); 

-- audit log for playlist-related user actions  

CREATE TABLE IF NOT EXISTS user_logs (
    log_id SERIAL PRIMARY KEY,

    user_id INT, -- user who performed action, nullable to preserve logs if user is deleted

    action_type VARCHAR(50) NOT NULL CHECK (
        action_type IN (
            'CREATE_PLAYLIST',
            'UPDATE_PLAYLIST',
            'DELETE_PLAYLIST',
            'ADD_SONG_TO_PLAYLIST',
            'REMOVE_SONG_FROM_PLAYLIST'
        )
    ),

    target_playlist_id INT, -- playlist_id that's being affected by the action

    description TEXT, -- additional context (e.g. song_id added/removed)

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);


/* ================== INDEXES ================== */ 


CREATE INDEX idx_song_artist_id ON song_artists(artist_id); 

CREATE INDEX idx_plays_song_id ON plays(song_id); 

CREATE INDEX idx_playlist_songs_song_id ON playlist_songs(song_id); 





/* ================== VIEWS ================== */ 


/* ================== TRIGGERS ================== */ 

-- CREATE PLAYLIST TRIGGER 
CREATE OR REPLACE FUNCTION log_create_playlist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_logs(
        user_id, action_type, target_playlist_id, description
) VALUES (
        NEW.user_id, 
		'CREATE_PLAYLIST',
        NEW.playlist_id,
		'Created playlist: "' || NEW.playlist_name || '"'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_playlist
AFTER INSERT ON playlists
FOR EACH ROW
EXECUTE FUNCTION log_create_playlist();


-- UPDATE PLAYLIST TRIGGER 
CREATE OR REPLACE FUNCTION log_update_playlist()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.playlist_name IS DISTINCT FROM OLD.playlist_name
	THEN
    INSERT INTO user_logs(
        user_id, action_type, target_playlist_id, description
) VALUES (
        NEW.user_id, 
		'UPDATE_PLAYLIST',
        NEW.playlist_id,
		'Renamed playlist from "' || OLD.playlist_name || '" to "' || NEW.playlist_name || '"'
    );
	END IF;
    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_playlist
AFTER UPDATE ON playlists
FOR EACH ROW
EXECUTE FUNCTION log_update_playlist();


--- DELETE PLAYLIST TRIGGER 
CREATE OR REPLACE FUNCTION log_delete_playlist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_logs(
        user_id, action_type, target_playlist_id, description
) VALUES (
        OLD.user_id, 
		'DELETE_PLAYLIST',
        OLD.playlist_id,
		'Deleted playlist: "' || OLD.playlist_name || '"'
    );
    RETURN OLD;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_delete_playlist
AFTER DELETE ON playlists
FOR EACH ROW
EXECUTE FUNCTION log_delete_playlist();


-- ADD SONG TO PLAYLIST TRIGGER 


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











