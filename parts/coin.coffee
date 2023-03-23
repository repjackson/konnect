if Meteor.isClient
    Router.route '/coin', (->
        @layout 'layout'
        @render 'coin'
        ), name:'coin'    
    
    Template.coin.onCreated ->
        @autorun => @subscribe 'my_coins', ->
    Template.coin.helpers 
        my_coins: ->
            Docs.find 
                model:'coin'
                _author_id:Meteor.userId()
    Template.coin.events
        'click .calc_coin': ->
            count = Docs.find(
                model:'coin'
                _author_id:Meteor.userId()
            ).count()
            Meteor.users.update Meteor.userId(),
                $set:
                    coins:count
        'click .mint_coin': ->
            Docs.insert
                model:'coin'
    Template.coin.events
        'click .transfer': ->
            new_id = 
                Docs.insert 
                    model:'transfer'
            Router.go "/transfer/#{new_id}/edit"
        
    
if Meteor.isServer
    Meteor.publish 'my_coins', ->
        Docs.find 
            model:'coin'
            _author_id:Meteor.userId()
        
        
        
if Meteor.isClient
    Template.account_finance.onCreated ->
        if Meteor.isDevelopment
            pub_key = Meteor.settings.public.stripe_test_publishable
        else if Meteor.isProduction
            pub_key = Meteor.settings.public.stripe_live_publishable
        Template.instance().checkout = StripeCheckout.configure(
            key: pub_key
            image: 'android-chrome-512x512.png'
            locale: 'auto'
            zipCode: true
            token: (token) ->
                amount = parseInt(Session.get('topup_amount'))
                # product = Docs.findOne Meteor.user()._model
                charge =
                    amount: amount*100
                    currency: 'usd'
                    source: token.id
                    description: token.description
                    # receipt_email: token.email
                Meteor.call 'credit_topup', charge, (err,res)=>
                    if err then alert err.reason, 'danger'
                    else
                        Swal.fire(
                            'topup processed',
                            ''
                            'success'
                        Docs.insert
                            model:'transaction'
                            transaction_type:'topup'
                            amount:amount
                        Meteor.users.update Meteor.userId(),
                            $inc: credit:amount
                        )
        )
        Template.account_finance.events
            'click .add_five_credits': ->
                console.log Template.instance()
                # if confirm 'add 5 credits?'
                Session.set('topup_amount',5)
                Template.instance().checkout.open
                    name: 'credit deposit'
                    # email:Meteor.user().emails[0].address
                    description: 'dao top up'
                    amount: 500
            'click .add_ten_credits': ->
                console.log Template.instance()
                # if confirm 'add 10 coin?'
                Session.set('topup_amount',10)
                Template.instance().checkout.open
                    name: 'credit deposit'
                    # email:Meteor.user().emails[0].address
                    description: 'dao top up'
                    amount: 1000
