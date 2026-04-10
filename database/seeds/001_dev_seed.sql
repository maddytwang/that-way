-- Development seed data
-- Run after 001_initial_schema.sql

INSERT INTO users (id, display_name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Dev User');

-- Known places for the dev user
INSERT INTO known_places (id, user_id, label, location, visit_count) VALUES
    (
        '00000000-0000-0000-0001-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'Home',
        ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326),  -- placeholder: SF
        20
    ),
    (
        '00000000-0000-0000-0001-000000000002',
        '00000000-0000-0000-0000-000000000001',
        'Work',
        ST_SetSRID(ST_MakePoint(-122.4089, 37.7853), 4326),
        18
    );
