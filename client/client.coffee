# @picked_sections = new ReactiveArray []
@picked_tags = new ReactiveArray []
@picked_user_tags = new ReactiveArray []
@picked_timestamp_tags = new ReactiveArray []
# @picked_ingredients = new ReactiveArray []

Template.home.onCreated ->
    Meteor.subscribe 'home_docs', ->

Template.home.helpers 
    home_docs: ->
        Docs.find 
            model:'post'
            home:true

Template.layout.events 
    'click .clear_search': -> 
        Session.set('event_search',null)
        picked_tags.clear()
Tracker.autorun ->
    current = Router.current()
    Tracker.afterFlush ->
        $(window).scrollTop 0


Template.footer.helpers
    doc_docs: ->
        Docs.find {}
    result_docs: ->
        Results.find {}

    user_docs: ->
        Meteor.users.find()
# Template.home.onCreated ->
#     @autorun => @subscribe 'model_docs', 'stats', ->
# Template.home.onRendered ->
#     Meteor.call 'log_homepage_view', ->
#         console.log '?'
# Template.home.helpers
#     stats: ->
#         Docs.findOne
#             model:'stats'

# Template.nav.onCreated ->
#     @autorun => @subscribe 'order_count'
#     @autorun => @subscribe 'product_count'
#     @autorun => @subscribe 'ingredient_count'
#     @autorun => @subscribe 'subscription_count'
#     @autorun => @subscribe 'source_count'
#     @autorun => @subscribe 'giftcard_count'
#     @autorun => @subscribe 'user_count'
        
        
Template.not_found.events
    'click .browser_back': -> window.history.back();



$.cloudinary.config
    cloud_name:"facet"
# Router.notFound =
    # action: 'not_found'

Template.layout.events
    'click .fly_right': (e,t)-> 
        # console.log 'hi'
        $(e.currentTarget).closest('.grid').transition('fly right', 500)
    'click .fly_up': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly up', 1000)
    'click .fly_down': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly down', 1000)
    'click .fly_left': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly left', 1000)
    # 'click .button': ->
    #     $(e.currentTarget).closest('.button').transition('bounce', 1000)

    'click a': ->
        $('.global_container')
        .transition('fade out', 200)
        .transition('fade in', 200)

    'click .log_view': ->
        # console.log Template.currentData()
        # console.log @
        Docs.update @_id,
            $inc: views: 1

# Template.layout.events
#     'click .button': ->
#         $('.global_container')
#         .transition('fade out', 10000)
#         .transition('fade in', 5000)


# Tracker.autorun ->
#     current = Router.current()
#     Tracker.afterFlush ->
#         $(window).scrollTop 0


# Stripe.setPublishableKey Meteor.settings.public.stripe_publishable
