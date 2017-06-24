db = require "lapis.db"

import create_table, types, drop_table, add_column, rename_column from require "lapis.db.schema"

Tracks = require "models.Tracks"

{
    [1]: =>
        create_table "episodes", {
            {"id", types.serial primary_key: true}
            {"title", types.text}
            {"description", types.text}
            {"tracklist", types.foreign_key array: true}
            {"download_uri", types.text unique: true}
            {"pubdate", types.time} -- not unique because a placeholder was used for unpublished episodes; in retrospect, a bad idea maybe
            {"status", types.integer default: 1}

            {"created_at", types.time}
            {"updated_at", types.time}
        }
        create_table "tracks", {
            {"id", types.serial primary_key: true}
            {"track", types.text unique: true}
            {"playcount", types.integer default: 0}
        }
        create_table "users", {
            {"id", types.serial primary_key: true}
            {"name", types.varchar unique: true}
            {"digest", types.text}
            {"admin", types.boolean default: false}
        }
    [2]: =>
        tracks = Tracks\select "WHERE track SIMILAR TO ?", "\n%|%\n%|%\n"
        for track in *tracks
            track\delete!
        track = Tracks\find track: ""
        track\delete!
}
