db = require "lapis.db"

import create_table, types, drop_table, add_column, rename_column from require "lapis.db.schema"

{
    [1]: =>
        create_table "episodes", {
            {"id", types.serial primary_key: true}
            {"title", types.text}
            {"description", types.text}
            {"tracklist", types.foreign_key array: true}
            {"download_uri", types.text unique: true}
            {"pubdate", types.time} -- not unique because a placeholder is used for unpublished episodes
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
}
