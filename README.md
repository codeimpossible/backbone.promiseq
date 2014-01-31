backbone.promiseq
=================

[![Build Status](https://travis-ci.org/codeimpossible/backbone.promiseq.png)](https://travis-ci.org/codeimpossible/backbone.promiseq)


Backbone.PromiseQ is a light-weight promise queue (get it?)


#### Example: fetching multiple models
``` javascript
var person = new Backbone.Model();
var pet = new Backbone.Model();

var queue = new Backbone.PromiseQ();

queue.then( person.fetch );
queue.then( person, function( p ) {
  pet.urlRoot = '/people/' + p.id + '/pets';
});
queue.then( pet.fetch );

// fetch the models
queue.run().then( function() {
  alert('person: ' + person.get('name') + ', pet: ' + pet.get('name'));
});
```

#### Example: Render a view when multiple models sync
``` javascript
var DashboardView = Backbone.View.extend({
    initialize: function() {
        var queue = this.queue = new Backbone.PromiseQ(arguments);

        this.listenTo(queue, 'run:success', this.render);

        queue.run();
    }
});
```
