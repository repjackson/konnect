Meteor.methods
    change_username:  (user_id,username) ->
        # user = Meteor.users.findOne _id:user_id
        Accounts.setUsername(user_id, username)
        return "Updated Username: #{username}"


    add_email: (user_id, new_email) ->
        Accounts.addEmail(user_id, new_email);
        return "Updated Email to #{new_email}"

    remove_email: (user_id, email)->
        # user = Meteor.users.findOne username:username
        console.log 'removing email', email, 'from', user_id
        Accounts.removeEmail user_id, email


    verify_email: (user_id)-> Accounts.sendVerificationEmail(user_id)

    validateEmail: (email) ->
        re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        re.test String(email).toLowerCase()