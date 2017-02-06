config = require "lapis.config"
import sql_password, session_secret from require "secret"

config {"production", "development"}, ->
    session_name "f5site"
    secret session_secret
    postgres ->
        host "127.0.0.1"
        user "postgres"
        password sql_password
    digest_rounds 9

config "production", ->
    postgres ->
        database "f5com"
    port 9152
    num_workers 4
    code_cache "on"

config "development", ->
    postgres ->
        database "f5dev"
    port 9153
    num_workers 2
    code_cache "off"
