-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
/* ================== RESET ================== */
DROP TABLE IF EXISTS playlist_songs CASCADE;
DROP TABLE IF EXISTS plays CASCADE;
DROP TABLE IF EXISTS playlists CASCADE;
DROP TABLE IF EXISTS song_artists CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS albums CASCADE;
DROP TABLE IF EXISTS artists CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS user_logs CASCADE;

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
-- 36.Create a view that shows each song along with its artist(s) and album name(if any).
DROP VIEW IF EXISTS v_artist_album_song;

CREATE OR REPLACE VIEW v_artist_album_song AS 
	SELECT 
		s.song_id,
		a.artist_name,
		COALESCE(al.album_name, 'Single') AS album_name,
		s.song_name 
	FROM songs s
	LEFT JOIN albums al
		ON s.album_id = al.album_id
	JOIN song_artists sa
		ON sa.song_id = s.song_id
	JOIN artists a
		ON a.artist_id = sa.artist_id;


-- 37.Create a view that summarizes total plays per song.

CREATE OR REPLACE VIEW v_plays_per_song AS 
	SELECT 
		s.song_id,
		s.song_name, 
		COUNT(p.play_id) AS play_count
	FROM songs s
	LEFT JOIN plays p
		ON s.song_id = p.song_id
	GROUP BY s.song_id, s.song_name; 


-- 38.Create a view that lists users and how many playlists they have created.

CREATE OR REPLACE VIEW v_user_playlists AS 
	SELECT 
		u.user_id, 
		u.user_name,
		COUNT(p.playlist_name) AS playlist_count
	FROM users u 
	LEFT JOIN playlists p
		ON u.user_id = p.user_id
	GROUP BY u.user_id, u.user_name;


-- 39. Create a view that only shows public playlists and enforce that no private playlist can be inserted through it.
CREATE OR REPLACE VIEW v_public_playlists AS
	SELECT 
	    playlist_id,
	    user_id,
	    playlist_name,
	    created_at,
	    p_type
	FROM playlists
	WHERE p_type = 'public'
	WITH CHECK OPTION;


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
CREATE OR REPLACE FUNCTION log_add_song()
RETURNS TRIGGER AS $$
DECLARE 
	v_user_id INT;
BEGIN
	SELECT user_id INTO v_user_id 
	FROM playlists 
	WHERE playlist_id = NEW.playlist_id;

    INSERT INTO user_logs(
        user_id, action_type, target_playlist_id, description
) VALUES (
        v_user_id, 
		'ADD_SONG_TO_PLAYLIST',
        NEW.playlist_id,
		'Added song id: ' || NEW.song_id
    );
    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_song
AFTER INSERT ON playlist_songs
FOR EACH ROW
EXECUTE FUNCTION log_add_song();

-- REMOVE SONG FROM PLAYLIST TRIGGER 
CREATE OR REPLACE FUNCTION log_remove_song()
RETURNS TRIGGER AS $$
DECLARE 
	v_user_id INT;
BEGIN
	SELECT user_id INTO v_user_id 
	FROM playlists 
	WHERE playlist_id = OLD.playlist_id;

    INSERT INTO user_logs(
        user_id, action_type, target_playlist_id, description
) VALUES (
        v_user_id, 
		'REMOVE_SONG_FROM_PLAYLIST',
        OLD.playlist_id,
		'Removed song id: ' || OLD.song_id
    );
    RETURN OLD;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_remove_song
AFTER DELETE ON playlist_songs
FOR EACH ROW
EXECUTE FUNCTION log_remove_song();

/* ================== INSERTS ================== */ 

/* 
 SEED DATA STRATEGY:
 - Core entities inserted manually (users, artists, songs)
 - Relationships explicitly defined
 - Additional users & playlists for realistic variety
 - Plays generated using random + biased distribution
*/


/* ---------- USERS ---------- */
INSERT INTO users (user_name, email, last_login) VALUES
('alice', 'alice@example.com', CURRENT_TIMESTAMP),
('bob', 'bob@example.com', NULL),
('charlie', 'charlie@example.com', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('diana', 'diana@example.com', NULL),
('eve', 'eve@example.com', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
('frank', 'frank@example.com', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('grace', 'grace@example.com', NULL),
('henry', 'henry@example.com', CURRENT_TIMESTAMP - INTERVAL '3 days'),
('irene', 'irene@example.com', CURRENT_TIMESTAMP),
('jack', 'jack@example.com', CURRENT_TIMESTAMP - INTERVAL '10 hours');

-- Add extra seed data for users:
INSERT INTO users (user_name, email, last_login) VALUES
('mia', 'mia@example.com', NULL),
('noah', 'noah@example.com', CURRENT_TIMESTAMP - INTERVAL '30 days'),
('oliver', 'oliver@example.com', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('sophia', 'sophia@example.com', CURRENT_TIMESTAMP - INTERVAL '90 days'),
('liam', 'liam@example.com', CURRENT_TIMESTAMP - INTERVAL '45 days');


/* ---------- ARTISTS ---------- */
INSERT INTO artists (artist_name, country) VALUES
('Coldplay', 'GB'),
('Taylor Swift', 'US'),
('Daft Punk', 'FR'),
('Unknown Indie', NULL);

/* ---------- EXTRA ARTISTS ---------- */
INSERT INTO artists (artist_name, country) VALUES
('Neon Dreams', 'CA'),
('Skyline Echo', NULL),
('Velvet Noise', 'AU'),
('Mono Signal', 'DE');

/* ---------- ARTIST WITH NO SONGS ---------- */
INSERT INTO artists (artist_name, country)
VALUES ('Ghost Artist', 'US');

/* ---------- ALBUMS ---------- */
INSERT INTO albums (album_name, label, release_year) VALUES
('Parachutes', 'Parlophone', 2000),
('1989', 'Big Machine', 2014),
('Random Access Memories', 'Columbia', 2013);

/* ---------- EXTRA ALBUMS ---------- */
INSERT INTO albums (album_name, label, release_year) VALUES
('Midnight Echoes', 'IndieWave', 1998),
('Future Silence', NULL, 2022),
('Acoustic Sessions', 'BlueRoom', 2007);

/* ---------- ALBUM WITH NO SONGS ---------- */
INSERT INTO albums (album_name, label, release_year)
VALUES ('Unreleased Vault', 'IndieWave', 2024);

/* ---------- SONGS ---------- */
INSERT INTO songs (album_id, song_name) VALUES
(1, 'Yellow'),
(1, 'Trouble'),
(1, 'Shiver'),
(2, 'Blank Space'),
(2, 'Style'),
(2, 'Shake It Off'),
(3, 'Get Lucky'),
(3, 'Instant Crush'),
(NULL, 'Loose Single'),
(NULL, 'Another Single');


/* ---------- EXTRA SONGS ---------- */
INSERT INTO songs (album_id, song_name) VALUES
(4, 'Static Lights'),
(4, 'Neon Streets'),
(4, 'City Dreams'),

(5, 'Digital Hearts'),
(5, 'Silent Frequency'),
(5, 'Electric Horizon'),

(6, 'Falling Slowly'),
(6, 'Midnight Rain'),
(6, 'Ocean View'),

(NULL, 'Lonely Satellite'),
(NULL, 'Summer Escape'),
(NULL, 'Broken Polaroid');

/* ---------- SONG_ARTISTS ---------- */
INSERT INTO song_artists (song_id, artist_id) VALUES
(1, 1), (2, 1), (3, 1),
(4, 2), (5, 2), (6, 2),
(7, 3), (8, 3),
(9, 4), (10, 4);


/* ---------- EXTRA SONG_ARTISTS ---------- */ 
INSERT INTO song_artists (song_id, artist_id) VALUES

-- Midnight Echoes album
(11, 5),
(12, 5),
(13, 5),

-- Future Silence album
(14, 6),
(15, 6),
(16, 6),

-- Acoustic Sessions album
(17, 7),
(18, 7),
(19, 7),

-- singles
(20, 8),
(21, 8),
(22, 5);

/* ---------- PLAYLISTS ---------- */
INSERT INTO playlists (user_id, playlist_name, p_type) VALUES
(1, 'Favorites', 'public'),
(1, 'Chill', 'private'),
(2, 'Workout', 'public'),
(3, 'Sad Songs', 'private'),
(2, 'Focus', 'private'),
(2, 'Party Mix', 'public'),
(3, 'Late Night', 'private'),
(4, 'Road Trip', 'public'),
(5, 'Indie Vibes', 'public'),
(6, 'Gym Hits', 'private'),
(7, 'Throwbacks', 'public');

/* ---------- EXTRA PLAYLISTS ---------- */
INSERT INTO playlists (user_id, playlist_name, p_type) VALUES
(8, 'Coding Mode', 'public'),
(9, 'Rainy Days', 'private'),
(10, 'Top Hits', 'public'),
(11, 'Deep Focus', 'private'),
(12, 'Summer Drive', 'public'),
(13, 'Lofi Nights', 'public'),
(14, 'Synthwave', 'private'),
(15, 'Morning Coffee', 'public');

/* ---------- EMPTY PLAYLISTS ---------- */
INSERT INTO playlists (user_id, playlist_name, p_type) VALUES
(5, 'Empty Draft', 'private'),
(8, 'To Organize', 'private');


/* ---------- PLAYLIST_SONGS ---------- */
INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES
-- original playlists
(1, 1, 1), (1, 4, 2), (1, 7, 3),
(2, 2, 1), (2, 9, 2),
(3, 7, 1),
(4, 2, 1), (4, 5, 2),

-- new playlists
(5, 1, 1), (5, 3, 2), (5, 4, 3),
(6, 5, 1), (6, 6, 2), (6, 7, 3),
(7, 2, 1), (7, 8, 2),
(8, 3, 1), (8, 6, 2), (8, 7, 3),
(9, 9, 1), (9, 10, 2),
(10, 5, 1), (10, 7, 2),
(11, 1, 1), (11, 8, 2);


/* ---------- EXTRA PLAYLIST_SONGS ---------- */

-- Delete seed data that was wrong:
DELETE FROM playlist_songs
WHERE playlist_id IN (
    SELECT playlist_id
    FROM playlists
    WHERE playlist_name IN (
        'Coding Mode',
        'Rainy Days',
        'Top Hits',
        'Deep Focus',
        'Summer Drive',
        'Lofi Nights',
        'Synthwave',
        'Morning Coffee'
    )
);


-- Correct insert:

INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES

-- Coding Mode
(19, 14, 3),
(19, 15, 4),
(19, 5, 5),
(19, 7, 6),

-- Rainy Days
(20, 2, 1),
(20, 17, 2),
(20, 18, 3),

-- Top Hits
(21, 1, 1),
(21, 4, 2),
(21, 7, 3),
(21, 14, 4),
(21, 21, 5),

-- Deep Focus
(22, 15, 1),
(22, 16, 2),
(22, 18, 3),
(22, 20, 4),

-- Summer Drive
(23, 5, 1),
(23, 6, 2),
(23, 12, 3),
(23, 21, 4),

-- Lofi Nights
(24, 17, 1),
(24, 18, 2),
(24, 19, 3),
(24, 20, 4),

-- Synthwave
(25, 11, 1),
(25, 12, 2),
(25, 14, 3),
(25, 15, 4),

-- Morning Coffee
(26, 3, 1),
(26, 9, 2),
(26, 17, 3);


/* ---------- PLAYS (BASE DATA) ---------- */
INSERT INTO plays (user_id, song_id, played_at) VALUES
(1, 1, CURRENT_TIMESTAMP),
(1, 4, CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(2, 7, CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(3, 2, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 1, CURRENT_TIMESTAMP - INTERVAL '2 days');


/* ---------- PLAYS (RANDOM ACTIVITY) ---------- */
-- simulate general listening over last 7 days
INSERT INTO plays (user_id, song_id, played_at)
SELECT 
    (RANDOM() * 9 + 1)::INT,
    (RANDOM() * 9 + 1)::INT,
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '7 days')
FROM generate_series(1, 120);


/* ---------- PLAYS ---------- */
-- make song_id = 1 clearly the most popular
INSERT INTO plays (user_id, song_id, played_at)
SELECT 
    (RANDOM() * 9 + 1)::INT,
    1,
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '3 days')
FROM generate_series(1, 60);

/* ---------- POWER USER ACTIVITY ---------- */
INSERT INTO plays (user_id, song_id, played_at)
SELECT
    11,
    (RANDOM() * 21 + 1)::INT,
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '5 days')
FROM generate_series(1, 40);


/* ---------- LIGHT USERS ---------- */
INSERT INTO plays (user_id, song_id, played_at) VALUES
(12, 3, CURRENT_TIMESTAMP - INTERVAL '8 days'),
(13, 7, CURRENT_TIMESTAMP - INTERVAL '12 days'),
(14, 11, CURRENT_TIMESTAMP - INTERVAL '15 days'),
(15, 20, CURRENT_TIMESTAMP - INTERVAL '20 days');



SELECT * FROM users;
SELECT * FROM artists;
SELECT * FROM albums;
SELECT * FROM songs;
SELECT * FROM song_artists;
SELECT * FROM playlists;
SELECT * FROM playlist_songs;
SELECT * FROM plays;
SELECT * FROM user_logs;



