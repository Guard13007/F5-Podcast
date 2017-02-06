is_admin = ->
    if @session.id
        if user = Users\find id: @session.id
            return user.admin
    return false

return {
    :is_admin
}
