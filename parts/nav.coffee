if Meteor.isClient
    Template.nav.onCreated ->
        @autorun => Meteor.subscribe 'me', ->
        # @autorun => Meteor.subscribe 'all_users', ->
        # @autorun => Meteor.subscribe 'models', ->
        
        @autorun => Meteor.subscribe 'model_count', 'post', ->
        @autorun => Meteor.subscribe 'model_count', 'task', ->
        @autorun => Meteor.subscribe 'model_count', 'rental', ->
        @autorun => Meteor.subscribe 'model_count', 'profile', ->
        @autorun => Meteor.subscribe 'model_count', 'product', ->
        @autorun => Meteor.subscribe 'model_count', 'group', ->
        @autorun => Meteor.subscribe 'model_count', 'event', ->
        @autorun => Meteor.subscribe 'model_count', 'transfer', ->
        @autorun => Meteor.subscribe 'user_count', ->
        # @autorun => Meteor.subscribe 'my_unread_messages'
        # @autorun => Meteor.subscribe 'global_stats'
        # @autorun => Meteor.subscribe 'my_cart_order'
        # @autorun => Meteor.subscribe 'my_cart_products'

    Template.nav.onRendered ->
        Meteor.setTimeout ->
            $('.menu .item')
                .popup()
        , 5000
                
    
    Template.nav.events
        'click .reset': ->
            # model_slug =  Router.current().params.model_slug
            Session.set 'loading', true
            Meteor.call 'set_facets', @slug, true, ->
                Session.set 'loading', false
    
        'click .clear_search': -> Session.set('product_query',null)
        'keyup .search_products': _.throttle((e,t)->
            # console.log Router.current().route.getName()
            current_name = Router.current().route.getName()
            # $(e.currentTarget).closest('.input').transition('pulse', 100)

            unless current_name is 'shop'
                Router.go '/shop'
            query = $('.search_products').val()
            Session.set('product_query', query)
            # console.log Session.get('product_query')
            if e.key == "Escape"
                Session.set('product_query', null)
                
            if e.which is 13
                search = $('#product_search').val().trim().toLowerCase()
                if search.length > 0
                    picked_tags.push search
                    console.log 'search', search
                    # Meteor.call 'log_term', search, ->
                    $('#product_search').val('')
                    Session.set('product_query', null)
                    # # $('#search').val('').blur()
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 500)
    
        'click .alerts': ->
            Session.set('viewing_alerts', !Session.get('viewing_alerts'))
            
        'click .toggle_admin': ->
            if 'admin' in Meteor.user().roles
                Meteor.users.update Meteor.userId(),
                    $pull:'roles':'admin'
            else
                Meteor.users.update Meteor.userId(),
                    $addToSet:'roles':'admin'
        'click .invert_toggle': ->
            # console.log 'hi'
            $('.item').transition('pulse', '1000')
            # $('.menu').transition('pulse', '1000')
            $('body').toggleClass('invert')
            # Meteor.users.update Meteor.userId(),
            #     $set:admin_mode:!Meteor.user().admin_mode
        'click .toggle_dev': ->
            if 'dev' in Meteor.user().roles
                Meteor.users.update Meteor.userId(),
                    $pull:'roles':'dev'
            else
                Meteor.users.update Meteor.userId(),
                    $addToSet:'roles':'dev'
        'click .view_user': ->
            Meteor.call 'calc_user_points', Meteor.userId(), ->
            
        'click .clear_tags': -> picked_tags.clear()
    
    
    Template.nav.helpers
        event_counter: -> Counts.get('event_counter')
        post_counter: -> Counts.get('post_counter')
        profile_counter: -> Counts.get('profile_counter')
        user_counter: -> Counts.get('user_count')
        group_counter: -> Counts.get('group_counter')
        task_counter: -> Counts.get('task_counter')
        transfer_counter: -> Counts.get('transfer_counter')
        rental_counter: -> Counts.get('rental_counter')
        product_counter: -> Counts.get('product_counter')
        
        current_product_search: -> Session.get('product_query')
        unread_count: ->
            unread_count = Docs.find({
                model:'message'
                to_username:Meteor.user().username
                read_by_ids:$nin:[Meteor.userId()]
            }).count()

        cart_amount: ->
            cart_amount = Docs.find({
                model:'cart_item'
                status:'cart'
                _author_id:Meteor.userId()
            }).count()
        cart_items: ->
            # co = 
            #     Docs.findOne 
            #         model:'order'
            #         status:'cart'
            #         _author_id:Meteor.userId()
            # if co 
            Docs.find 
                model:'cart_item'
                _author_id: Meteor.userId()
                # order_id:co._id
                # status:'cart'
                
        alert_toggle_class: ->
            if Session.get('viewing_alerts') then 'active' else ''
        unread_count: ->
            Docs.find( 
                model:'message'
                recipient_id:Meteor.userId()
                read_ids:$nin:[Meteor.userId()]
            ).count()
    Template.nav.events
        'mouseenter a': (e,t)-> $(e.currentTarget).closest('a').transition('pulse', '1000')
        'mouseenter a': (e,t)-> $(e.currentTarget).closest('a').transition('pulse', '1000')
    # Template.secnav.events
    #     'mouseenter .item': (e,t)-> $(e.currentTarget).closest('.item').transition('pulse', '1000')
    #     'click .menu_dropdown': ->
    #         $('.menu_dropdown').dropdown(
    #             on:'hover'
    #         )

    #     'click #logout': ->
    #         Session.set 'logging_out', true
    #         Meteor.logout ->
    #             Session.set 'logging_out', false
    #             Router.go '/'


    Template.nav.helpers

if Meteor.isServer
    Meteor.publish 'models', ->
        Docs.find 
            model:'model'
    Meteor.publish 'my_cart', ->
        Docs.find 
            model:'cart_item'
