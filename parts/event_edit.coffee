if Meteor.isClient
    Router.route '/event/:doc_id/edit', (->
        @layout 'layout'
        @render 'event_edit'
        ), name:'event_edit'

    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'model_docs', 'room_reservation'
    Template.event_edit.onRendered ->
    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'room'
    Template.event_edit.helpers
        rooms: ->
            Docs.find   
                model:'room'


    Template.event_edit.events
        'click .delete_item': ->
            if confirm 'delete item?'
                Docs.remove @_id

        'click .select_room': ->
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    room_id:event.room_id 
                    date:event.date
            console.log reservation_exists
            unless reservation_exists            
                Docs.update Router.current().params.doc_id,
                    $set:
                        room_id:@_id
                        room_title:@title

        'click .submit': ->
            Docs.update Router.current().params.doc_id,
                $set:published:true
            if confirm 'confirm?'
                Meteor.call 'send_event', @_id, =>
                    Router.go "/event/#{@_id}/view"


    Template.event_edit.helpers
        reservation_exists: ->
            event = Docs.findOne Router.current().params.doc_id
            Docs.findOne
                model:'room_reservation'
                # room_id:event.room_id 
                date:event.date
        room_button_class: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    # room_id:event.room_id 
                    date:event.date
            res = ''
            if event.room_id is @_id
                res += 'blue'
            else 
                res += 'basic'
            if reservation_exists
                # console.log 'res exists'
                res += ' disabled'
            else
                console.log 'no res'
            res
    
        room_reservations: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.find 
                model:'room_reservation'
                room_id:event.room_id 
                date:event.date
                
    Template.reserve_button.helpers
        event_room: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
        slot_res: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.findOne
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
    
    
    Template.reserve_button.events
        'click .cancel_res': ->
            Swal.fire({
                title: "confirm delete reservation?"
                text: ""
                icon: 'question'
                showCancelButton: true,
                confirmButtonText: 'confirm'
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
            )
        'click .reserve_slot': ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.insert 
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
                payment:'points'

if Meteor.isServer
    Meteor.methods
        send_event: (event_id)->
            event = Docs.findOne event_id
            target = Meteor.users.findOne event.recipient_id
            gifter = Meteor.users.findOne event._author_id

            console.log 'sending event', event
            Meteor.users.update target._id,
                $inc:
                    points: event.amount
            Meteor.users.update gifter._id,
                $inc:
                    points: -event.amount
            Docs.update event_id,
                $set:
                    submitted:true
                    submitted_timestamp:Date.now()



            Docs.update Router.current().params.doc_id,
                $set:
                    submitted:true
