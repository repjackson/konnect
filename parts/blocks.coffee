if Meteor.isClient
    Template.favorite_icon_toggle.events
        'click .toggle_fav': ->
            if @favorite_ids and Meteor.userId() in @favorite_ids
                Docs.update @_id, 
                    $pull:favorite_ids:Meteor.userId()
            else
                $('body').toast(
                    showIcon: 'heart'
                    message: "marked favorite"
                    showProgress: 'bottom'
                    class: 'success'
                    # displayTime: 'auto',
                    position: "bottom right"
                )

                Docs.update @_id, 
                    $addToSet:favorite_ids:Meteor.userId()

    Template.qr_code.events 
        'click .make_qr': ->
            new QRCode(document.getElementById("qrcode"), "https://www.loom.gratis");
            # or
            # qrcode = new QRCode("test", {
            #  text: "http://www.geeksforgeeks.org",
            #  width: 256,
            #  height: 256,
            #  colorDark : "#000000",
            #  colorLight : "#ffffff",
            #  correctLevel : QRCode.CorrectLevel.H
            # });

    Template.tip_button.events 
        'click .tip': ->
            new_transfer = {model:'transfer'}
            doc = Docs.findOne @_id
            user = Meteor.users.findOne @_id
            if doc 
                new_transfer.parent_id = @_id
                new_transfer.parent_model = @model
                new_transfer.target_user_id = @_author_id
            else if user 
                new_transfer.target_user_id = @_id
            new_id = Docs.insert new_transfer
            Router.go "/transfer/#{new_id}/edit"
    Template.friend_button.events 
        'click .friend': ->
            Meteor.users.update Meteor.userId(),
                $addToSet: 
                    friend_ids:@_id
                    friend_usernames:@username
            $('body').toast(
                showIcon: 'thumbs up'
                message: "friended"
                showProgress: 'bottom'
                class: 'success'
                displayTime: 'auto',
                position: "bottom right"
            )
        'click .unfriend': ->
            Meteor.users.update Meteor.userId(),
                $pull: 
                    friend_ids:@_id
                    friend_usernames:@username
            $('body').toast(
                showIcon: 'minus'
                message: "unfriended"
                showProgress: 'bottom'
                class: 'success'
                displayTime: 'auto',
                position: "bottom right"
            )
                    
    Template.friend_button.helpers
        is_friend: ->
            Meteor.user().friend_ids and @_id in Meteor.user().friend_ids
        user_friends: ->
            current_user = Meteor.users.findOne username:Router.current().params.username
            Meteor.users.find 
                _id:$in:current_user.friend_ids
            
        friended_by: ->
            current_user = Meteor.users.findOne username:Router.current().params.username
            Meteor.users.find 
                _id:$in:current_user.friend_ids
                    
    Template.session_toggle.events
        'click .toggle_session_var': ->
            Session.set(@key, !Session.get(@key))
            $('body').toast(
                # showIcon: 'heart'
                message: "#{@key} #{Session.get(@key)}"
                # showProgress: 'bottom'
                # class: 'success'
                displayTime: 'auto',
                position: "bottom right"
            )

    Template.session_toggle.helpers
        session_toggle_class: ->
            if Session.get(@key) then 'active' else 'basic'
   
    Template.print_this.events
        'click .print': -> console.log @
   
    Template.bookmark_button.helpers
        is_bookmarked: ->
            Meteor.user().bookmark_ids and @_id in Meteor.user().bookmark_ids
            
    Template.bookmark_button.events
        'click .toggle_bookmark': ->
            if Meteor.user().bookmark_ids and @_id in Meteor.user().bookmark_ids
                Meteor.users.update Meteor.userId(), 
                    $pull: 
                        bookmark_ids:@_id
                $('body').toast(
                    showIcon: 'bookmark'
                    message: 'bookmark removed'
                    # showProgress: 'bottom'
                    class: 'info'
                    displayTime: 'auto',
                    position: "bottom right"
                )
                        
            else 
                Meteor.users.update Meteor.userId(), 
                    $addToSet: 
                        bookmark_ids:@_id
                $('body').toast(
                    showIcon: 'bookmark'
                    message: 'bookmark added'
                    # showProgress: 'bottom'
                    class: 'success'
                    displayTime: 'auto',
                    position: "bottom right"
                )
                
   
    Template.comments.onRendered ->
        Meteor.setTimeout ->
            $('.accordion').accordion()
        , 1000
    Template.comments.onCreated ->
        # if Router.current().params.doc_id
        #     parent = Docs.findOne Router.current().params.doc_id
        # else
        # parent = Docs.findOne Template.parentData()._id
        if parent
            @autorun => Meteor.subscribe 'children', 'comment', @data._id, ->
    Template.comments.helpers
        doc_comments: ->
            # if Router.current().params.doc_id
            #     parent = Docs.findOne Router.current().params.doc_id
            # else
            parent = Template.currentData()
            Docs.find
                parent_id:parent._id
                model:'comment'
                
                
    Template.comments.events
        'keyup .add_comment': (e,t)->
            if e.which is 13
                # if Router.current().params.doc_id
                #     parent = Docs.findOne Router.current().params.doc_id
                # else
                parent = Template.currentData()
                # parent = Docs.findOne Router.current().params.doc_id
                comment = t.$('.add_comment').val()
                Docs.insert
                    parent_id: parent._id
                    model:'comment'
                    parent_model:parent.model
                    body:comment
                t.$('.add_comment').val('')

        'click .remove_comment': ->
            if confirm 'Confirm remove comment'
                Docs.remove @_id

    Template.follow.helpers
        followers: ->
            Meteor.users.find
                _id: $in: @follower_ids
        following: -> @follower_ids and Meteor.userId() in @follower_ids
    Template.follow.events
        'click .follow': ->
            Docs.update @_id,
                $addToSet:follower_ids:Meteor.userId()
        'click .unfollow': ->
            Docs.update @_id,
                $pull:follower_ids:Meteor.userId()

    # Template.set_limit.events
    #     'click .set_limit': ->
    #         Session.set('limit', @amount)

    Template.set_sort_key.helpers
        sort_button_class: ->
            if Session.equals('sort_key', @key) then 'blue' else 'basic compact'
    Template.set_sort_key.events
        'click .set_sort': ->
            Session.set('sort_key', @key)
            Session.set('post_sort_label', @label)
            Session.set('post_sort_icon', @icon)




    Template.voting.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @


    Template.voting_small.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @



    # Template.doc_card.onCreated ->
    #     @autorun => Meteor.subscribe 'doc_by_id', Template.currentData().doc_id
    # Template.doc_card.helpers
    #     doc: ->
    #         Docs.findOne
    #             _id:Template.currentData().doc_id





    # Template.call_watson.events
    #     'click .autotag': ->
    #         doc = Docs.findOne Router.current().params.doc_id
    #
    #         Meteor.call 'call_watson', doc._id, @key, @mode

    Template.voting_full.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @




    Template.role_editor.onCreated ->
        @autorun => Meteor.subscribe 'model', 'role'



    # Template.user_card.onCreated ->
    #     @autorun => Meteor.subscribe 'user_from_username', @data
    # Template.user_card.helpers
    #     user: -> Meteor.users.findOne @valueOf()




    # Template.big_user_card.onCreated ->
    #     @autorun => Meteor.subscribe 'user_from_username', @data
    # Template.big_user_card.helpers
    #     user: -> Meteor.users.findOne username:@valueOf()




    # Template.username_info.onCreated ->
    #     @autorun => Meteor.subscribe 'user_from_username', @data
    # Template.username_info.events
    #     'click .goto_user': ->
    #         user = Meteor.users.findOne username:@valueOf()
    #         if user.is_current_member
    #             Router.go "/member/#{user.username}/"
    #         else
    #             Router.go "/user/#{user.username}/"
    # Template.username_info.helpers
    #     user: -> Meteor.users.findOne username:@valueOf()




    # Template.user_info.onCreated ->
    #     @autorun => Meteor.subscribe 'user_from_id', @data
    # Template.user_info.helpers
    #     user: -> Meteor.users.findOne @valueOf()


    Template.toggle_edit.events
        'click .toggle_edit': ->




    # Template.user_list_info.onCreated ->
    #     @autorun => Meteor.subscribe 'user', @data

    # Template.user_list_info.helpers
    #     user: ->
    #         Meteor.users.findOne @valueOf()



    # Template.user_field.helpers
    #     key_value: ->
    #         user = Meteor.users.findOne Router.current().params.doc_id
    #         user["#{@key}"]

    # Template.user_field.events
    #     'blur .user_field': (e,t)->
    #         value = t.$('.user_field').val()
    #         Meteor.users.update Router.current().params.doc_id,
    #             $set:"#{@key}":value


    Template.goto_model.events
        'click .goto_model': ->
            Session.set 'loading', true
            Meteor.call 'set_facets', @slug, ->
                Session.set 'loading', false





    Template.viewing.events
        'click .mark_read': (e,t)->
            Docs.update @_id,
                $inc:views:1
            unless @read_ids and Meteor.userId() in @read_ids
                Meteor.call 'mark_read', @_id, ->
                    # $(e.currentTarget).closest('.comment').transition('pulse')
                    $('.unread_icon').transition('pulse')
        'click .mark_unread': (e,t)->
            Docs.update @_id,
                $inc:views:-1
            Meteor.call 'mark_unread', @_id, ->
                # $(e.currentTarget).closest('.comment').transition('pulse')
                $('.unread_icon').transition('pulse')
    Template.viewing.helpers
        viewed_by: -> 
            @read_ids and Meteor.userId() in @read_ids
        readers: ->
            readers = []
            if @read_ids
                for reader_id in @read_ids
                    unless reader_id is @author_id
                        readers.push Meteor.users.findOne reader_id
            readers




    Template.add_button.onCreated ->
        Meteor.subscribe 'model_from_slug', @data.model
    Template.add_button.helpers
        model: ->
            data = Template.currentData()
            Docs.findOne
                model: 'model'
                slug: data.model
    Template.add_button.events
        'click .add': ->
            new_id = Docs.insert
                model: @model
            Router.go "/m/#{@model}/#{new_id}/edit"


    Template.delete_button.events
        'click .remove_doc': (e,t)->
            if confirm "remove #{@model}?"
                if $(e.currentTarget).closest('.card')
                    $(e.currentTarget).closest('.card').transition('fly right', 1000)
                else
                    $(e.currentTarget).closest('.segment').transition('fly right', 1000)
                    $(e.currentTarget).closest('.item').transition('fly right', 1000)
                    $(e.currentTarget).closest('.content').transition('fly right', 1000)
                    $(e.currentTarget).closest('tr').transition('fly right', 1000)
                    $(e.currentTarget).closest('.event').transition('fly right', 1000)
                Meteor.setTimeout =>
                    Docs.remove @_id
                , 1000

    Template.remove_icon.events
        'click .remove_doc': (e,t)->
            if confirm "remove #{@model}?"
                if $(e.currentTarget).closest('.card')
                    $(e.currentTarget).closest('.card').transition('fly right', 1000)
                else
                    $(e.currentTarget).closest('.segment').transition('fly right', 1000)
                    $(e.currentTarget).closest('.item').transition('fly right', 1000)
                    $(e.currentTarget).closest('.content').transition('fly right', 1000)
                    $(e.currentTarget).closest('tr').transition('fly right', 1000)
                    $(e.currentTarget).closest('.event').transition('fly right', 1000)
                Meteor.setTimeout =>
                    Docs.remove @_id
                , 1000

    Template.session_set.events
        'click .set_session_value': ->
            if Session.equals(@key, @value)
                Session.set(@key,null)
            else
                Session.set(@key, @value)

    Template.session_set.helpers
        calculated_class: ->
            res = ''
            if @cl
                res += @cl
            if Session.equals(@key,@value)
                res += ' blue'
            else 
                res += ' '
            res

    



    Template.key_value_edit.events
        'click .set_key_value': ->
            # Docs.update Router.current().params.doc_id,
            context = Template.parentData()
            if context
                Docs.update context._id, 
                    $set:
                        "#{@key}":@value
            # Session.set(@key, @value)

    Template.key_value_edit.helpers
        calculated_class: ->
            res = ''
            # doc = Docs.findOne Router.current().params.doc_id
            doc = Template.parentData()
            
            if @cl
                res += @cl
            # if Session.equals(@key,@value)
            if doc["#{@key}"]  is @value
                res += ' black'
            else 
                res += ' basic'
            res



    

    Template.session_boolean_toggle.events
        'click .toggle_session_key': ->
            Session.set(@key, !Session.get(@key))

    Template.session_boolean_toggle.helpers
        calculated_class: ->
            res = ''
            if @cl
                res += @cl
            if Session.get(@key)
                res += ' blue'
            else
                res += ' basic'

            res

if Meteor.isServer
    Meteor.methods
        'send_kiosk_message': (message)->
            parent = Docs.findOne message.parent._id
            Docs.update message._id,
                $set:
                    sent: true
                    sent_timestamp: Date.now()
            Docs.insert
                model:'log_event'
                log_type:'kiosk_message_sent'
                text:"kiosk message sent"


    Meteor.publish 'children', (model, parent_id, limit)->
        limit = if limit then limit else 10
        Docs.find {
            model:model
            parent_id:parent_id
        }, limit:limit
        
        
if Meteor.isClient
    Template.doc_array_togggle.helpers
        doc_array_toggle_class: ->
            parent = Template.parentData()
            # user = Meteor.users.findOne Router.current().params.username
            if parent["#{@key}"] and @value in parent["#{@key}"] then 'active' else 'basic'
    Template.doc_array_togggle.events
        'click .toggle': (e,t)->
            parent = Template.parentData()
            if parent["#{@key}"]
                if @value in parent["#{@key}"]
                    Docs.update parent._id,
                        $pull: "#{@key}":@value
                else
                    Docs.update parent._id,
                        $addToSet: "#{@key}":@value
            else
                Docs.update parent._id,
                    $addToSet: "#{@key}":@value


    # Template.friend_finder.onCreated ->
    #     @user_results = new ReactiveVar
    # Template.friend_finder.helpers
    #     user_results: ->Template.instance().user_results.get()
    # Template.friend_finder.events
    #     'click .clear_results': (e,t)->
    #         t.user_results.set null
    
    #     'keyup .find_friend': (e,t)->
    #         search_value = $(e.currentTarget).closest('.find_friend').val().trim()
    #         if search_value.length > 1
    #             Meteor.call 'lookup_user', search_value, @role_filter, (err,res)=>
    #                 if err then console.error err
    #                 else
    #                     t.user_results.set res
    
    #     'click .select_user': (e,t) ->
    #         page_doc = Docs.findOne Router.current().params.doc_id
    #         field = Template.currentData()
    
    
    
    #         val = t.$('.edit_text').val()
    #         if field.direct
    #             parent = Template.parentData()
    #         else
    #             parent = Template.parentData(5)
    
    #         doc = Docs.findOne parent._id
    #         if doc
    #             Docs.update parent._id,
    #                 $set:"#{field.key}":@_id
    #         else
    #             Meteor.users.update parent._id,
    #                 $set:"#{field.key}":@_id
                
    #         t.user_results.set null
    #         $('.find_friend').val ''
    #         # Docs.update page_doc._id,
    #         #     $set: assignment_timestamp:Date.now()
    
    #     'click .pull_user': ->
    #         if confirm "remove #{@username}?"
    #             parent = Template.parentData(1)
    #             field = Template.currentData()
    #             doc = Docs.findOne parent._id
    #             if doc
    #                 Docs.update parent._id,
    #                     $unset:"#{field.key}":1
    #             else
    #                 Meteor.users.update parent._id,
    #                     $unset:"#{field.key}":1
    
    #         #     page_doc = Docs.findOne Router.current().params.doc_id
    #             # Meteor.call 'unassign_user', page_doc._id, @
    
    
if Meteor.isClient
    Template.group_picker.onCreated ->
        Session.setDefault('group_search','')
        @autorun => @subscribe 'group_search_results', Session.get('group_search'), ->
        # @autorun => @subscribe 'model_docs', 'group', ->
    Template.group_picker.helpers
        group_results: ->
            if Session.get('group_search').length > 1
                Docs.find 
                    model:'group'
                    title: {$regex:"#{Session.get('group_search')}",$options:'i'}
                
        product_groups: ->
            product = Docs.findOne Router.current().params.doc_id
            Docs.find 
                # model:'group'
                _id:$in:product.group_ids
        group_search_value: ->
            Session.get('group_search')
        
    Template.group_picker.events
        'click .clear_search': (e,t)->
            Session.set('group_search', null)
            t.$('.group_search').val('')

            
        'click .remove_group': (e,t)->
            if confirm "remove #{@title} group?"
                Docs.update Router.current().params.doc_id,
                    $pull:
                        group_ids:@_id
                        group_titles:@title
        'click .pick_group': (e,t)->
            Docs.update Router.current().params.doc_id,
                $addToSet:
                    group_ids:@_id
                    group_titles:@title
            Session.set('group_search',null)
            t.$('.group_search').val('')
                    
        'keyup .group_search': (e,t)->
            # if e.which is '13'
            val = t.$('.group_search').val()
            Session.set('group_search', val)

        'click .create_group': ->
            new_id = 
                Docs.insert 
                    model:'group'
                    title:Session.get('group_search')
            Router.go "/group/#{new_id}/edit"


if Meteor.isServer 
    Meteor.publish 'group_search_results', (group_title_query='')->
        if group_title_query.length>1
            Docs.find 
                model:'group'
                title: {$regex:"#{group_title_query}",$options:'i'}

