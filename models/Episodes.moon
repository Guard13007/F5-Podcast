import Model from require "lapis.db.model"

class Episodes extends Model
    @statuses: enum {
        draft: 1
        published: 2
    }

    @timestamp: true
