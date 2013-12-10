backbone.promiseq
=================

Backbone.PromiseQ is a light-weight promise queue (get it?)


Example, fetching multiple models
``` javascript
var person = new Backbone.Model(),
    pet = new Backbone.Model();
    
var queue = new Backbone.PromiseQ();

queue.enqueue( person.fetch );
queue.enqueue( person, function( p ) {
  pet.urlRoot = '/people/' + p.id + '/pets';
});
queue.enqueue( pet.fetch );

// fetch the models
queue.run().then( function() {
  alert('person: ' + person.get('name') + ', pet: ' + pet.get('name'));
});
```
