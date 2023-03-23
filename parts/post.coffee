if Meteor.isClient
    Router.route '/posts', (->
        @layout 'layout'
        @render 'posts'
        ), name:'posts'
    Router.route '/post/:doc_id/edit', (->
        @layout 'layout'
        @render 'post_edit'
        ), name:'post_edit'
    Router.route '/post/:doc_id', (->
        @layout 'layout'
        @render 'post_view'
        ), name:'post_view'
    Router.route '/post/:doc_id/view', (->
        @layout 'layout'
        @render 'post_view'
        ), name:'post_view_long'
    
    
    # Template.posts.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'post', ->
    Template.posts.onCreated ->
        Session.setDefault 'view_mode', 'cards'
        Session.setDefault 'sort_key', '_timestamp'
        Session.setDefault 'sort_direction', -1
        Session.setDefault 'sort_label', 'added'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.posts.onCreated ->
        # @autorun => @subscribe 'model_docs', 'post', ->
        @autorun => @subscribe 'post_facets',
            picked_tags.array()
            # Session.get('limit')
            # Session.get('sort_key')
            # Session.get('sort_direction')
            # Session.get('view_delivery')
            # Session.get('view_pickup')
            # Session.get('view_open')

        @autorun => @subscribe 'post_results',
            picked_tags.array()
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('group_title_search')
            Session.get('limit')
            # Session.get('view_delivery')
            # Session.get('view_pickup')
            # Session.get('view_open')

    Template.post_view.onCreated ->
        @autorun => @subscribe 'related_groups',Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_by_doc_id', Router.current().params.doc_id, ->
    Template.post_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.post_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.posts.events
        'click .pick_post_tag': -> picked_tags.push @name
        'click .unpick_post_tag': -> picked_tags.remove @valueOf()
    Template.posts.helpers
        post_docs: ->
            Docs.find {
                model:'post'
            }, sort:"#{Session.get('sort_key')}":Session.get('sort_direction')
        tag_results: ->
            Results.find 
                model:'post_tag'
        picked_post_tags: -> picked_tags.array()
        
                
    Template.nav.events
        'click .add_post': ->
            new_id = 
                Docs.insert 
                    model:'post'
            Router.go "/post/#{new_id}/edit"
    Template.posts.events
        'click .add_post': ->
            new_id = 
                Docs.insert 
                    model:'post'
            Router.go "/post/#{new_id}/edit"
    Template.post_card.events
        'click .view_post': ->
            Router.go "/post/#{@_id}"
    Template.post_item.events
        'click .view_post': ->
            Router.go "/post/#{@_id}"

    # Template.post_view.events
    #     'click .add_post_recipe': ->
    #         new_id = 
    #             Docs.insert 
    #                 model:'recipe'
    #                 post_ids:[@_id]
    #         Router.go "/recipe/#{new_id}/edit"

    Template.favorite_icon_toggle.helpers
        icon_class: ->
            if @favorite_ids and Meteor.userId() in @favorite_ids
                'red'
            else
                'outline'
    
    
    Template.post_edit.events
        'click .delete_post': ->
            Swal.fire({
                title: "delete post?"
                text: "cannot be undone"
                icon: 'question'
                confirmButtonText: 'delete'
                confirmButtonColor: 'red'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'post removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/posts"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish post?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_post', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'post published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish post?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_post', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'post unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'home_docs', ()->
        Docs.find 
            model:'post'
            home:true
    Meteor.publish 'post_results', (
        picked_tags=[]
        sort_key='_timestamp'
        sort_direction=-1
        limit=25
        )->
        @unblock()

        # console.log picked_ingredients
        # if doc_limit
        #     limit = doc_limit
        # else
        # if doc_sort_key
        #     sort_key = doc_sort_key
        # if doc_sort_direction
        #     sort_direction = parseInt(doc_sort_direction)
        self = @
        match = {model:'post'}
        # if picked_ingredients.length > 0
        #     match.ingredients = $all: picked_ingredients
        #     # sort = 'price_per_serving'
        # if picked_sections.length > 0
        #     match.menu_section = $all: picked_sections
            # sort = 'price_per_serving'
        # else
            # match.tags = $nin: ['wikipedia']
        # sort = '_timestamp'
        # match.published = true
            # match.source = $ne:'wikipedia'
        # if view_vegan
        #     match.vegan = true
        # if view_gf
        #     match.gluten_free = true
        # if post_query and post_query.length > 1
        #     console.log 'searching post_query', post_query
        #     match.title = {$regex:"#{post_query}", $options: 'i'}
        #     # match.tags_string = {$regex:"#{query}", $options: 'i'}
        if picked_tags.length > 0
            match.tags = $all: picked_tags
            
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array

        # console.log 'post match', match
        # console.log 'sort key', sort_key
        # console.log 'sort direction', sort_direction
        unless Meteor.userId()
            match.private = $ne:true
        Docs.find match,
            sort:"#{sort_key}":sort_direction
            # sort:_timestamp:-1
            limit: limit
            fields:
                title:1
                model:1
                image_id:1
                body:1
                _author_id:1
                youtube_id:1
                tags:1
                _timestamp:1
            
            
    Meteor.publish 'post_count', (
        picked_ingredients
        picked_sections
        post_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'post'}
        if picked_ingredients.length > 0
            match.ingredients = $all: picked_ingredients
            # sort = 'price_per_serving'
        if picked_sections.length > 0
            match.menu_section = $all: picked_sections
            # sort = 'price_per_serving'
        # else
            # match.tags = $nin: ['wikipedia']
        sort = '_timestamp'
            # match.source = $ne:'wikipedia'
        if view_vegan
            match.vegan = true
        if view_gf
            match.gluten_free = true
        if post_query and post_query.length > 1
            console.log 'searching post_query', post_query
            match.title = {$regex:"#{post_query}", $options: 'i'}
        Counts.publish this, 'post_counter', Docs.find(match)
        return undefined

    Meteor.publish 'post_facets', (
        picked_tags
        post_query
        doc_limit
        doc_sort_key
        doc_sort_direction
        )->
        @unblock()
        # console.log 'dummy', dummy
        # console.log 'query', query

        self = @
        match = {}
        match.model = 'post'
            # match.$regex:"#{post_query}", $options: 'i'}
        # if post_query and post_query.length > 1
        #     console.log 'searching post_query', post_query
        #     match.title = {$regex:"#{post_query}", $options: 'i'}
        #     # match.tags_string = {$regex:"#{query}", $options: 'i'}
        if picked_tags.length > 0
            match.tags = $all: picked_tags
        result_count = Docs.find(match).count()
        console.log 'match for tags', match, 'count:',result_count
        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $match: count: $lt: result_count }
            # { $match: _id: {$regex:"#{post_query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 15 }
            { $project: _id: 0, name: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
        
        tag_cloud.forEach (tag, i) =>
            # console.log 'queried tag ', tag
            # console.log 'key', key
            self.added 'results', Random.id(),
                name: tag.name
                count: tag.count
                model:'post_tag'
                # category:key
                # index: i


        self.ready()


if Meteor.isClient
    Template.post_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'
    Template.post_card.events
        'click .quickbuy': ->
            console.log @
            Session.set('quickbuying_id', @_id)
            # $('.ui.dimmable')
            #     .dimmer('show')
            # $('.special.cards .image').dimmer({
            #   on: 'hover'
            # });
            # $('.card')
            #   .dimmer('toggle')
            $('.ui.modal')
              .modal('show')

        'click .goto_food': (e,t)->
            # $(e.currentTarget).closest('.card').transition('zoom',420)
            # $('.global_container').transition('scale', 500)
            Router.go("/food/#{@_id}")
            # Meteor.setTimeout =>
            # , 100

        # 'click .view_card': ->
        #     $('.container_')

    Template.post_card.helpers
        post_card_class: ->
            count = Docs.find(model:'post').count()
            if count is 1
                'fluid'
            # if Session.get('quickbuying_id')
            #     if Session.equals('quickbuying_id', @_id)
            #         'raised'
            #     else
            #         'active medium dimmer'
        is_quickbuying: ->
            Session.equals('quickbuying_id', @_id)

        food: ->
            # console.log Meteor.user().roles
            Docs.find {
                model:'food'
            }, sort:title:1
            