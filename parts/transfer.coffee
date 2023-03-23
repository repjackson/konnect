if Meteor.isClient
    Router.route '/transfers', (->
        @layout 'layout'
        @render 'transfers'
        ), name:'transfers'
    Template.transfers.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true
        @autorun => @subscribe 'transfer_facets',
            picked_tags.array()
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_delivery')
            Session.get('view_pickup')
            Session.get('view_open')

        @autorun => @subscribe 'transfer_results',
            picked_tags.array()
            Session.get('transfer_title_search')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_delivery')
            Session.get('view_pickup')
            Session.get('view_open')
    Template.transfers.events
        'click .add_transfer': ->
            new_id =
                Docs.insert
                    model:'transfer'
            Router.go("/transfer/#{new_id}/edit")
        'keyup .search_transfer': _.throttle((e,t)->
            query = $('.search_transfer').val()
            Session.set('transfer_title_search', query)
            
            console.log Session.get('transfer_title_search')
            if e.which is 13
                search = $('.search_transfer').val().trim().toLowerCase()
                if search.length > 0
                    picked_tags.push search
                    console.log 'search', search
                    # Meteor.call 'log_term', search, ->
                    $('.search_transfer').val('')
                    Session.set('transfer_title_search', null)
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 500)


        'click .pick_transfer_tag': -> picked_tags.push @name
        'click .unpick_transfer_tag': -> picked_tags.remove @valueOf()
        # console.log picked_tags.array()
        # if picked_tags.array().length is 1
            # Meteor.call 'call_wiki', search, ->

        # if picked_tags.array().length > 0
            # Meteor.call 'search_reddit', picked_tags.array(), ->

        'click .clear_picked_tags': ->
            Session.set('current_transfer_search',null)
            picked_tags.clear()

        'keyup #search': _.throttle((e,t)->
            query = $('#search').val()
            Session.set('current_transfer_search', query)
            # console.log Session.get('current_transfer_search')
            if e.which is 13
                search = $('#search').val().trim().toLowerCase()
                if search.length > 0
                    picked_tags.push search
                    console.log 'search', search
                    # Meteor.call 'log_term', search, ->
                    $('#search').val('')
                    Session.set('current_transfer_search', null)
                    # # $('#search').val('').blur()
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 1000)

        'click .calc_transfer_count': ->
            Meteor.call 'calc_transfer_count', ->

        # 'keydown #search': _.throttle((e,t)->
        #     if e.which is 8
        #         search = $('#search').val()
        #         if search.length is 0
        #             last_val = picked_tags.array().slice(-1)
        #             console.log last_val
        #             $('#search').val(last_val)
        #             picked_tags.pop()
        #             Meteor.call 'search_reddit', picked_tags.array(), ->
        # , 1000)

        'click .reconnect': ->
            Meteor.reconnect()


        'click .set_sort_direction': ->
            if Session.get('transfer_sort_direction') is -1
                Session.set('transfer_sort_direction', 1)
            else
                Session.set('transfer_sort_direction', -1)
    Template.transfers.helpers
        sorting_up: -> parseInt(Session.get('transfer_sort_direction')) is 1

        # toggle_open_class: -> if Session.get('view_open') then 'blue' else ''
        # connection: ->
        #     console.log Meteor.status()
        #     Meteor.status()
        # connected: ->
        #     Meteor.status().connected
        transfer_tag_results: ->
            # if Session.get('current_transfer_search') and Session.get('current_transfer_search').length > 1
            #     Terms.find({}, sort:count:-1)
            # else
            transfer_count = Docs.find().count()
            # console.log 'transfer count', transfer_count
            # if transfer_count < 3
            #     Results.find({count: $lt: transfer_count})
            # else
            Results.find()

        current_transfer_search: -> Session.get('current_transfer_search')

        result_class: ->
            if Template.instance().subscriptionsReady()
                ''
            else
                'disabled'

        picked_transfer_tags: -> picked_tags.array()
        # picked_tags_plural: -> picked_tags.array().length > 1
        searching: -> Session.get('searching')

        one_post: ->
            Docs.find().count() is 1
        transfer_docs: ->
            # if picked_tags.array().length > 0
            Docs.find {
                model:'transfer'
            },
                sort: "#{Session.get('transfer_sort_key')}":parseInt(Session.get('transfer_sort_direction'))
                # limit:Session.get('transfer_limit')

        home_subs_ready: ->
            Template.instance().subscriptionsReady()
        users: ->
            # if picked_tags.array().length > 0
            Meteor.users.find {
            },
                sort: count:-1
                # limit:1


        # timestamp_tags: ->
        #     # if picked_tags.array().length > 0
        #     Timestamp_tags.find {
        #         # model:'reddit'
        #     },
        #         sort: count:-1
        #         # limit:1

        transfer_limit: ->
            Session.get('transfer_limit')

        current_transfer_sort_label: ->
            Session.get('transfer_sort_label')


if Meteor.isServer
    Meteor.publish 'transfer_results', (
        picked_tags
        title_search=''
        doc_limit
        doc_sort_key
        doc_sort_direction
        view_delivery
        view_pickup
        view_open
        )->
        # console.log picked_tags
        match = {model:'transfer'}
        if doc_limit
            limit = doc_limit
        else
            limit = 42
        if title_search.length > 0
            match.title = {$regex:"#{title_search}", $options: 'i'}

        if doc_sort_key
            sort_key = doc_sort_key
        if doc_sort_direction
            sort_direction = parseInt(doc_sort_direction)
        self = @
        # if view_open
        #     match.open = $ne:false
        # if view_delivery
        #     match.delivery = $ne:false
        # if view_pickup
        #     match.pickup = $ne:false
        if picked_tags.length > 0
            match.tags = $all: picked_tags
            sort = 'member_count'
        else
            # match.tags = $nin: ['wikipedia']
            sort = '_timestamp'
            # match.source = $ne:'wikipedia'
        # if view_images
        #     match.is_image = $ne:false
        # if view_videos
        #     match.is_video = $ne:false

        # match.tags = $all: picked_tags
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array

        console.log 'transfer match', match
        console.log 'sort key', sort_key
        console.log 'sort direction', sort_direction
        Docs.find match,
            # sort:"#{sort_key}":sort_direction
            sort:_timestamp:-1
            limit: limit
    Meteor.publish 'transfer_facets', (
        picked_tags=[]
        picked_timestamp_tags
        query
        doc_limit
        doc_sort_key
        doc_sort_direction
        view_delivery
        view_pickup
        view_open
        )->
        # console.log 'dummy', dummy
        # console.log 'query', query
        # console.log 'selected tags', picked_tags

        self = @
        match = {}
        match.model = 'transfer'
        # if view_open
        #     match.open = $ne:false

        # if view_delivery
        #     match.delivery = $ne:false
        # if view_pickup
        #     match.pickup = $ne:false
        if picked_tags.length > 0 then match.tags = $all: picked_tags
            # match.$regex:"#{current_transfer_search}", $options: 'i'}
        total_count = Docs.find(match).count()
        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: count: $lt: total_count }
            { $sort: count: -1, _id: 1 }
            { $limit: 20 }
            { $project: _id: 0, name: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }

        tag_cloud.forEach (tag, i) =>
            # console.log 'transfer tag result ', tag
            self.added 'results', Random.id(),
                name: tag.name
                count: tag.count
                model:'transfer_tag'
                # category:key
                # index: i


        self.ready()




if Meteor.isClient
    Router.route '/transfer/:doc_id/', (->
        @render 'transfer_view'
        ), name:'transfer_view'

    Template.transfer_view.onCreated ->
        @autorun => Meteor.subscribe 'recipient_from_transfer_id', Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'product_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
        # @autorun => Meteor.subscribe 'all_users'
        
    Template.transfer_view.onRendered ->



if Meteor.isServer
    Meteor.publish 'product_from_transfer_id', (transfer_id)->
        transfer = Docs.findOne transfer_id
        Docs.find 
            _id:transfer.product_id
if Meteor.isClient
    Router.route '/transfer/:doc_id/edit', (->
        @layout 'layout'
        @render 'transfer_edit'
        ), name:'transfer_edit'
        
        
    Template.transfer_edit.onCreated ->
        @autorun => Meteor.subscribe 'recipient_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id, ->', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => @subscribe 'tag_results',
            # Router.current().params.doc_id
            picked_tags.array()
            Session.get('searching')
            Session.get('current_query')
            Session.get('dummy')
        
    Template.transfer_edit.onRendered ->


    Template.transfer_edit.helpers
        # terms: ->
        #     Terms.find()
        suggestions: ->
            Results.find(model:'tag')
        recipient: ->
            transfer = Docs.findOne Router.current().params.doc_id
            if transfer and transfer.recipient_id
                Meteor.users.findOne
                    _id: transfer.recipient_id
        members: ->
            transfer = Docs.findOne Router.current().params.doc_id
            Meteor.users.find({
                # levels: $in: ['member','domain']
                _id: $ne: Meteor.userId()
            }, {
                sort:points:1
                limit:10
                })
        # subtotal: ->
        #     transfer = Docs.findOne Router.current().params.doc_id
        #     transfer.amount*transfer.recipient_ids.length
        
        point_max: ->
            if Meteor.user().username is 'one'
                1000
            else 
                Meteor.user().points
        
        can_send: ->
            transfer = Docs.findOne Router.current().params.doc_id
            transfer.amount and transfer.recipient_id
            Meteor.user().coins > transfer.amount
    Template.transfer_edit.events
        'click .add_recipient': ->
            Docs.update Router.current().params.doc_id,
                $set:
                    recipient_id:@_id
        'click .remove_recipient': ->
            Docs.update Router.current().params.doc_id,
                $unset:
                    recipient_id:1
        'keyup .new_tag': _.throttle((e,t)->
            query = $('.new_tag').val()
            if query.length > 0
                Session.set('searching', true)
            else
                Session.set('searching', false)
            Session.set('current_query', query)
            
            if e.which is 13
                element_val = t.$('.new_tag').val().toLowerCase().trim()
                Docs.update Router.current().params.doc_id,
                    $addToSet:tags:element_val
                picked_tags.push element_val
                Meteor.call 'log_term', element_val, ->
                Session.set('searching', false)
                Session.set('current_query', '')
                Session.set('dummy', !Session.get('dummy'))
                t.$('.new_tag').val('')
        , 1000)

        'click .remove_element': (e,t)->
            element = @valueOf()
            field = Template.currentData()
            picked_tags.remove element
            Docs.update Router.current().params.doc_id,
                $pull:tags:element
            t.$('.new_tag').focus()
            t.$('.new_tag').val(element)
            Session.set('dummy', !Session.get('dummy'))
    
    
        'click .select_term': (e,t)->
            # picked_tags.push @title
            Docs.update Router.current().params.doc_id,
                $addToSet:tags:@title
            picked_tags.push @title
            $('.new_tag').val('')
            Session.set('current_query', '')
            Session.set('searching', false)
            Session.set('dummy', !Session.get('dummy'))

    
        'blur .edit_description': (e,t)->
            textarea_val = t.$('.edit_textarea').val()
            Docs.update Router.current().params.doc_id,
                $set:description:textarea_val
    
    
        'blur .edit_text': (e,t)->
            val = t.$('.edit_text').val()
            Docs.update Router.current().params.doc_id,
                $set:"#{@key}":val
    
    
        'blur .point_amount': (e,t)->
            # console.log @
            val = parseInt t.$('.point_amount').val()
            Docs.update Router.current().params.doc_id,
                $set:amount:val



        'click .cancel_transfer': ->
            Swal.fire({
                title: "confirm cancel?"
                text: ""
                icon: 'question'
                showCancelButton: true,
                confirmButtonColor: 'red'
                confirmButtonText: 'confirm'
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Router.go '/'
            )
            
        'click .submit': ->
            Swal.fire({
                title: "confirm send #{@amount}pts?"
                text: ""
                icon: 'question'
                showCancelButton: true,
                confirmButtonColor: 'green'
                confirmButtonText: 'confirm'
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'send_transfer', @_id, =>
                        Swal.fire(
                            title:"#{@amount} sent"
                            icon:'success'
                            showConfirmButton: false
                            position: 'top-end',
                            timer: 1000
                        )
                        Router.go "/transfer/#{@_id}"
            )



if Meteor.isServer
    Meteor.publish 'recipient_from_transfer_id', (transfer_id)->
        transfer = Docs.findOne transfer_id
        if transfer
            Meteor.users.find transfer.recipient_id
    Meteor.methods
        send_transfer: (transfer_id)->
            transfer = Docs.findOne transfer_id
            recipient = Meteor.users.findOne transfer.recipient_id
            transferer = Meteor.users.findOne transfer._author_id

            console.log 'sending transfer', transfer
            Meteor.call 'recalc_one_stats', recipient._id, ->
            Meteor.call 'recalc_one_stats', transfer._author_id, ->
    
            Docs.update transfer_id,
                $set:
                    submitted:true
                    submitted_timestamp:Date.now()
            return