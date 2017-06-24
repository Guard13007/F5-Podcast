lapis = require "lapis"
db = require "lapis.db"

import respond_to from require "lapis.application"
import is_admin from require "helpers"
import insert from table

Episodes = require "models.Episodes"
Tracks = require "models.Tracks"
Users = require "users.models.Users"

class extends lapis.Application
    @before_filter =>
        u = @req.parsed_url
        if u.path != "/users/login"
            @session.redirect = "#{u.scheme}://#{u.host}#{u.path}"
        if @session.info
            @info = @session.info
            @session.info = nil

    @include "users/users"
    @include "githook/githook"

    layout: "default"

    "*": =>
        return redirect_to: @url_for("index")

    [index: "/(:page[%d])"]: =>
        episodes = Episodes\paginated "WHERE status = ? ORDER BY pubdate DESC", Episodes.statuses.published, per_page: 10
        page = tonumber(@params.page) or 1
        episodes = episodes\get_page page

        @html ->
            script src: @build_url "static/js/marked.min.js"
            link rel: "stylesheet", href: @build_url "static/highlight/styles/solarized-dark.css"
            script src: @build_url "static/highlight/highlight.pack.js"
            script -> raw "
                marked.setOptions({
                    highlight: function(code) { return hljs.highlightAuto(code).value; },
                    smartypants: true
                });
                hljs.initHighlightingOnLoad();
            "

            for episode in *episodes
                h2 episode.title
                h4 episode.pubdate\sub 1, 10

                div id: "post_#{episode.id}"
                script -> raw "document.getElementById('post_#{episode.id}').innerHTML = marked('#{episode.description\gsub("\\", "\\\\\\\\")\gsub("'", "\\'")\gsub("\n", "\\n")\gsub("\r", "")}');"

                div ->
                    a href: @url_for("post", pubdate: episode.pubdate), "Full Post"
                    text " | "
                    a href: @build_url(episode.download_uri), target: "_blank", "Listen Now"

            --TODO navigation!

    -- redirects from the original form of post URLs
    "/post/:id[%d]": =>
        episode = Episodes\find id: @params.id
        return redirect_to: @url_for("post", pubdate: episode.pubdate), status: 301

    [post: "/post/:pubdate"]: =>
        episode = Episodes\find pubdate: @params.pubdate\gsub "%%20", " "
        unless episode.status == Episodes.statuses.published
            return redirect_to: @url_for("index")

        @html ->
            h2 episode.title
            h4 episode.pubdate\sub 1, 10

            script src: @build_url "static/js/marked.min.js"
            link rel: "stylesheet", href: @build_url "static/highlight/styles/solarized-dark.css"
            script src: @build_url "static/highlight/highlight.pack.js"
            script -> raw "
                marked.setOptions({
                    highlight: function(code) { return hljs.highlightAuto(code).value; },
                    smartypants: true
                });
                hljs.initHighlightingOnLoad();
            "
            div id: "post_#{episode.id}"
            script -> raw "document.getElementById('post_#{episode.id}').innerHTML = marked('#{episode.description\gsub("\\", "\\\\\\\\")\gsub("'", "\\'")\gsub("\n", "\\n")\gsub("\r", "")}');"

            tracks = Tracks\find_all episode.tracklist
            ol ->
                for track in *tracks
                    li track.track
            div ->
                a href: @build_url(episode.download_uri), target: "_blank", "Listen Now"

                if is_admin @
                  text " | "
                  a href: @url_for("post_edit", id: episode.id), "Edit Post"

    [post_edit: "/edit/:id[%d]"]: respond_to {
        before: =>
            unless @session.id
                @write redirect_to: @url_for "index"
            user = Users\find id: @session.id
            unless user and user.admin
                @write redirect_to: @url_for "index"

        GET: =>
            episode = Episodes\find id: @params.id
            unless episode
                @write redirect_to: @url_for "index"

            tracks = Tracks\find_all episode.tracklist
            tracklist_text = ""
            for track in *tracks
                tracklist_text ..= track.track .. "\n"

            @html ->
                form {
                    action: @url_for "post_edit", id: episode.id
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Title: "
                    input type: "text", name: "title", value: episode.title
                    p "Description: "
                    textarea cols: 80, rows: 13, name: "description", episode.description
                    p "Tracklist (Separated by newlines, 'Artist - Title [Album]'): "
                    textarea cols: 80, rows: 13, name: "tracklist", tracklist_text
                    p "Download URI: "
                    input type: "text", name: "download_uri", value: episode.download_uri\gsub "%%20", " "
                    p "Publish Date: "
                    input type: "text", name: "pubdate", value: episode.pubdate
                    br!
                    element "select", name: "status", ->
                        for status in *Episodes.statuses
                            if status == episode.status
                                option value: Episodes.statuses[status], selected: true, status
                            else
                                option value: Episodes.statuses[status], status
                    input type: "hidden", name: "id", value: episode.id
                    input type: "submit"

        POST: =>
            episode = Episodes\find id: @params.id
            unless episode
                @write redirect_to: @url_for "index"

            tracks = Tracks\find_all episode.tracklist
            tracklist, new_tracks, removed_tracks = {}, {}, {}
            for name in (@params.tracklist.."\n")\gmatch ".-\n"
                table.insert tracklist, name\sub(1, -2)
            for track in *tracks
                unless tracklist[track.track]
                    table.insert removed_tracks, track
            for track in *tracklist
                exists = false
                for t in *tracks
                    if t.track == track
                        exists = true
                        break
                unless exists
                    table.insert new_tracks, track

            local public_playcount
            if episode.status == Episodes.statuses.published
                public_playcount = 1
            else
                public_playcount = 0

            for track in *removed_tracks
                track\update {
                  playcount: track.playcount - public_playcount
                }

            for track in *new_tracks
                if t = Tracks\find track: track
                    t\update { playcount: t.playcount + public_playcount }
                else
                    t = Tracks\create {
                        track: track
                        playcount: public_playcount
                    }

            tracks = {}
            for track in *tracklist
                t = Tracks\find track: track
                table.insert tracks, t.id

            pubdate = @params.pubdate
            if episode.status == Episodes.statuses.draft and @params.status == Episodes.statuses.published
                pubdate = db.format_date!
                for track in *tracks
                    track\update { playcount: track.playcount + 1 }

            episode\update {
                title: @params.title
                description: @params.description
                download_uri: @params.download_uri
                status: @params.status
                pubdate: pubdate
                tracklist: db.array tracks
            }

            @session.info = "Post Updated!"
            return redirect_to: @url_for("post_edit", id: episode.id)
    }

    [rss: "/rss"]: =>
        --TODO actually RSS feed

        @html ->
            p "Coming soon! (I just haven't written a generator yet and I'm working on stuffs.)"

    [new: "/new"]: respond_to {
        before: =>
            unless @session.id
                @write redirect_to: @url_for "index"
            user = Users\find id: @session.id
            unless user and user.admin
                @write redirect_to: @url_for "index"

        GET: =>
            @html ->
                form {
                    action: @url_for "new"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Title: "
                    input type: "text", name: "title"
                    p "Description: "
                    textarea cols: 80, rows: 13, name: "description"
                    p "Tracklist (Separated by newlines, 'Artist - Title [Album]'): "
                    textarea cols: 80, rows: 13, name: "tracklist"
                    p "File name: "
                    input type: "text", name: "file_name"
                    br!
                    element "select", name: "status", ->
                        for status in *Episodes.statuses
                            if status == Episodes.statuses.draft
                                option value: Episodes.statuses[status], selected: true, status
                            else
                                option value: Episodes.statuses[status], status
                    input type: "submit"

        POST: =>
            --title & description should exist, but don't need to be verified
            --tracklist needs to be processed (playcounts not updated for drafts!)
            --file_name needs to be turned into download_uri

            tracks = {}
            pubdate = db.format_date!

            local public_playcount
            if @params.status == Episodes.statuses.published
                public_playcount = 1
            else
                public_playcount = 0

            for name in (@params.tracklist.."\n")\gmatch ".-\n"
                if track = Tracks\find track: name\sub 1, -2
                    track\update { playcount: track.playcount + public_playcount }
                    insert tracks, track.id
                else
                    track = Tracks\create {
                        track: name\sub(1, -2)
                        playcount: public_playcount
                    }
                    insert tracks, track.id

            episode = Episodes\create {
                title: @params.title
                description: @params.description
                download_uri: "static/mp3/#{@params.file_name}"
                status: @params.status
                pubdate: pubdate
                tracklist: db.array tracks
            }

            if episode.status == Episodes.statuses.published
                return redirect_to: @url_for("post", pubdate: episode.pubdate)
            else
                return redirect_to: @url_for("post_edit", id: episode.id)
    }

    [tracklist: "/tracklist"]: =>
        tracks = Tracks\select "* ORDER BY playcount DESC"
        @html ->
            div ->
                a href: @url_for("tracklist_alphabetical"), "Alphabetical"
                if is_admin @
                    text " | "
                    a href: @url_for("tracklist_edit"), "Edit Tracks"
            element "table", ->
                tr ->
                    th "Artist - Title [Album]"
                    th "Play count"
                for track in *tracks
                    tr ->
                        td track.track
                        td track.playcount

    [tracklist_alphabetical: "/tracklist/alphabetical"]: =>
        tracks = Tracks\select "* ORDER BY track ASC"
        @html ->
            div ->
                a href: @url_for("tracklist"), "Play count"
                if is_admin @
                    text " | "
                    a href: @url_for("tracklist_edit"), "Edit Tracks"
            element "table", ->
                tr ->
                    th "Artist - Title [Album]"
                    th "Play count"
                for track in *tracks
                    tr ->
                        td track.track
                        td track.playcount

    [tracklist_edit: "/tracklist/edit"]: respond_to {
        before: =>
            unless @session.id
                @write redirect_to: @url_for "index"
            user = Users\find id: @session.id
            unless user and user.admin
                @write redirect_to: @url_for "index"

        GET: =>
            render: true

        POST: =>
            track = Tracks\find id: @params.id
            track\update {
                track: @params.track
                playcount: tonumber(@params.playcount)
            }

            @info = "Track updated."
            render: true
    }

    --"/run-once": =>
        --episodes = Episodes\select "*"
        --for episode in *episodes
        --    for i=1,#episode.tracklist
        --        if episode.tracklist[i] == 9 or episode.tracklist[i] == 10
        --            episode.tracklist[i] = 25
        --            episode\update {tracklist: db.array episode.tracklist}
        --track = Tracks\find id: 9
        --track\delete!
        --track = Tracks\find id: 10
        --track\delete!
        --@html -> p "Done."
