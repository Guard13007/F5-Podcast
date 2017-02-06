import Widget from require "lapis.html"

Tracks = require "models.Tracks"

class extends Widget
    content: =>
        tracks = Tracks\select "* ORDER BY track ASC"
        div ->
            a href: @url_for("tracklist_alphabetical"), "Alphabetical"
            text " | "
            a href: @url_for("tracklist"), "Play count"
        element "table", ->
            tr ->
                th "track"
                th "playcount"
                th "submit"
            for track in *tracks
                tr ->
                    form {
                        action: @url_for "tracklist_edit"
                        method: "POST"
                        enctype: "multipart/form-data"
                    }, ->
                        td -> input type: "text", name: "track", value: track.track
                        td -> input type: "number", name: "playcount", value: track.playcount
                        td ->
                            input type: "hidden", name: "id", value: track.id
                            input type: "submit", value: "Update"
