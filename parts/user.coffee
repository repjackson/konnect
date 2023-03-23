if Meteor.isClient
    Router.route '/user/:username', (->
        @layout 'layout'
        @render 'user'
        ), name:'user'



    Template.user.onCreated ->
    Template.user.onCreated ->
        @autorun -> Meteor.subscribe 'user_hosted_events', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_going_events', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_comments', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'username_model_docs', Router.current().params.username, 'comment', ->
        # @autorun => Meteor.subscribe 'user', Router.current().params.username
        # @autorun => Meteor.subscribe 'model_docs', 'order'
        
        @autorun => Meteor.subscribe 'user_groups', Router.current().params.username, ->
        @autorun => Meteor.subscribe 'user_posts', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_from_username', Router.current().params.username, ->
        # @autorun -> Meteor.subscribe 'user_referenced_docs', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_event_tickets', Router.current().params.username, ->
        # @autorun -> Meteor.subscribe 'model_docs', 'event'
    Template.user.onRendered ->
        Meteor.setTimeout ->
            $('.accordion').accordion()
        , 1000

        
    Template.user_points.events
        'click .send_points': ->
            user = Meteor.users.findOne username:Router.current().params.username
            new_id = 
                Docs.insert 
                    model:'transfer'
                    recipient_id:user._id
                    recipient_username:user.username
            Router.go "/transfer/#{new_id}/edit"
                
    Template.user.events
        'click .toggle_group_members': -> Session.set('view_group_members', !Session.get('view_group_members'))
    
        'click .user_credit_segment': ->
            Router.go "/transfer/#{@_id}"
            
        'click .user_debit_segment': ->
            Router.go "/transfer/#{@_id}"
            
            
    Template.user.helpers
        current_user: ->
            Meteor.users.findOne username:Router.current().params.username

        user: ->
            Meteor.users.findOne username:Router.current().params.username
    
    
    
        user_event_tickets: ->
            current_user = Meteor.users.findOne(username:Router.current().params.username)
            Docs.find {
                model:'transaction'
                transaction_type:'ticket_purchase'
            }, 
                sort: _timestamp:-1
                limit: 10

        user_post_docs: ->
            user = Meteor.users.findOne username:@username
            Docs.find
                model:'post'
                _author_id:user._id
        user_going_events: ->
            user = Meteor.users.findOne username:@username
            Docs.find {
                model:'event'
                going_user_ids:$in:[user._id]
            }, sort:start_datetime:-1
        user_hosted_events: ->
            user = Meteor.users.findOne username:@username
            Docs.find
                model:'event'
                host_id:user._id

    Template.user_groups.onCreated ->
        Session.setDefault 'view_group_members', true
        @autorun -> Meteor.subscribe 'user_member_groups', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_leader_groups', Router.current().params.username, ->


    Template.user_groups.helpers 
        user_member_groups: ->
            user = Meteor.users.findOne username:@username
            Docs.find
                model:'group'
                member_ids:$in:[user._id]
            
        user_leader_groups: ->
            user = Meteor.users.findOne username:@username
            Docs.find
                model:'group'
                group_leader_ids:$in:[user._id]



if Meteor.isServer 
    Meteor.publish 'user_bookmark_docs', ->
        Docs.find 
            _id:$in:Meteor.user().bookmark_ids
            
    Meteor.publish 'user_posts', (username)->
        user = Meteor.users.findOne username:username
        Docs.find 
            model:'post'
            _author_id:user._id

    Meteor.publish 'user_hosted_events', (username)->
        user = Meteor.users.findOne username:username
        Docs.find 
            model:'event'
            host_id:user._id


if Meteor.isClient 
    Template.user.onRendered ->
        Meteor.setTimeout ->
            $('.button').popup()
        , 2000


    # Template.user_section.helpers
    #     user_section_template: ->
    #         "user_#{Router.current().params.group}"


    Template.user.events
        'click .logout_other_clients': ->
            Meteor.logoutOtherClients()

        'click .logout': ->
            Router.go '/login'
            Meteor.logout()
            
        'click .boop': (e,t)->
            $(e.currentTarget).closest('.image').transition('bounce', 500)
            user = Meteor.users.findOne username:Router.current().params.username
            $('body').toast(
                showIcon: 'hand point down outline'
                message: "boop"
                showProgress: 'bottom'
                class: 'success'
                displayTime: '750',
                position: "bottom center"
            )
            Meteor.users.update user._id,
                $inc:boops:1
            
    # Template.topup_button.events
    #     'click .topup': ->
            
    #         $('body').toast(
    #             showIcon: 'food'
    #             message: "100 points added"
    #             showProgress: 'bottom'
    #             class: 'success'
    #             # displayTime: 'auto',
    #             position: "bottom right"
    #         )
    #         Docs.insert 
    #             model:'topup'
    #             amount:100
    #         Meteor.call 'calc_user_credit', Meteor.userId(), ->
    #         # Meteor.users.update Meteor.userId(),
    #         #     $inc:
    #         #         points:@amount
            
            
if Meteor.isServer
    Meteor.methods
        'calc_user_credit': (user_id)->
            total_points = 0
            topups = 
                Docs.find 
                    model:'topup'
                    _author_id:Meteor.userId()
                    amount:$exists:true
            for topup in topups.fetch()
                total_points += topup.amount
            console.log total_points
            
            Meteor.users.update Meteor.userId(),
                $set:points:total_points
            
            
    Meteor.publish 'username_model_docs', (username, model)->
        user = Meteor.users.findOne username:username
        # if username 
        Docs.find {
            model:model
            _author_id:user._id
        }, limit:20
        # else 
        #     Docs.find   
        #         model:model
        #         _author_username:Meteor.user().username            
                
                
                

if Meteor.isServer
    Meteor.publish 'user_event_tickets', (username)->
        user = Meteor.users.findOne username:username
        if user
            Docs.find({
                model:'transaction'
                transaction_type:'ticket_purchase'
                _author_id:user._id
            },{
                limit:20
                sort: _timestamp:-1
            })
        
        
        
        

if Meteor.isServer
    Meteor.methods 
        enter_group: (group_id)->
            Meteor.users.update Meteor.userId(),
                $set:
                    current_group_id:group_id
    
    Meteor.publish 'user_member_groups', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'group'
            member_ids:$in:[user._id]
            
    Meteor.publish 'user_leader_groups', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'group'
            group_leader_ids:$in:[user._id]
            
    Meteor.publish 'user_going_events', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'event'
            going_user_ids:$in:[user._id]
    Meteor.publish 'user_event_maybe', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'event'
            maybe_user_ids:$in:[user._id]
    Meteor.publish 'user_event_not_going', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'event'
            not_user_ids:$in:[user._id]
            
            