html = require "lapis.html"

Users = require "users.models.Users"

class extends html.Widget
    content: =>
        html_5 ->
            head ->
                meta charset: "utf-8"
                title "F5 Podcast, refresh for music"
                link rel: "stylesheet", type: "text/css", href: @build_url("static/font/timeburner_regular.css")
                link rel: "stylesheet", type: "text/css", href: @build_url("static/css/style.css")
            body ->
                div id: "container", ->
                    h1 -> a href: @url_for("index"), "F5 Podcast"
                    h4 "refresh for music"

                    p "F5 is about music. Play a variety or limited subset of music, not really sure which."
                    p "Right now, I am running a series of experimental episodes. Eventually I hope to produce good consistent regular episodes."

                    div ->
                        a href: @url_for("rss"), "Subscribe to RSS feed"
                        text " | "
                        a href: "https://guard13007.com", target: "_blank", "Other Stuff I Do"
                        text " | "
                        a href: "mailto:refreshformusic@gmail.com", "Email"
                        text " | "
                        a href: @url_for("tracklist"), "Full Tracklist"
                        if @session.id
                            if user = Users\find id: @session.id
                                if user.admin
                                    text " | "
                                    a href: @url_for("new"), "New Episode"

                    hr!

                    if @info
                        text @info
                        hr!

                    --TODO remove this crap
                    p "Temporary warning! I am in the process of rebuilding this website/show right now, so things are derp derp."
                    hr!

                    @content_for "inner"
