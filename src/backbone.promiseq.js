// Backbone.PromiseQ
// =================
//
// v0.2.0
// (c) 2010-2013 Jared Barboza
// Backbone.PromiseQ is freely distributable under the Apache license v2.0

(function (root, factory) {
  if (typeof exports === 'object') {

    var underscore = require('underscore');
    var backbone = require('backbone');
    var jQuery = require('jquery');

    module.exports = factory(underscore, jQuery, backbone);

  } else if (typeof define === 'function' && define.amd) {

    define(['underscore', 'jquery', 'backbone'], factory);

  } else {
    root.PromiseQ = factory(root._, root.jQuery, root.Backbone );
  }
})(this, function (_, $, Backbone) {
  var PromiseQ = function( /* args */ ) {
    var tasks = [],
      // stores the jQuery Deferred object for use in other methods
      deferred,
      shouldExitQueue = false,
      currentTask = -1;

    // #### flush method
    // empties the queue, useful if you want to reuse your queues. Be careful! This will completely
    // remove all the tasks from the current queue. DO NOT CALL WHEN RUNNING A QUEUE.
    this.flush = function() {
      var cpy = tasks.slice();

      tasks = [];
      this.length = 0;
      currentTask = -1;

      return cpy;
    };

    // #### then method
    // adds a task to the current queue. A task is a function that may or may not return a jQuery promise.
    // if two arguments are passed to `then` then it assumes that the first is a context and the second is the
    // task. In this case, the task will be called with the context as the first argument.
    this.then = function( /* args */ ) {
      var args = Array.prototype.slice.call(arguments),
          task;

      // push either a simple task or a targeted task into the task collection
      if( args.length === 1 ) {
        task = args[0];
      } else {
        task = { target: args[0], fn: args[1] };
      }

      tasks.push(task);
      this.length = tasks.length;

      // return the current queue instance to promote chaining
      return this;
    };

    // #### At method
    // returns the task at the specified index
    this.at = function( index ) {
      return tasks[index];
    };

    // #### Peek method
    // peeks ahead or behind in the queue relative to the current task
    this.peek = function( step ) {
      var index = currentTask + step;
      if( index < tasks.length && index >= 0 ) {
        return this.at(index);
      }
      return;
    };

    // #### Next method
    // returns the next item in the queue or `undefined` if there are no more items
    this.next = function() {
      currentTask += 1;
      if( currentTask < tasks.length ) {
        return this.at( currentTask );
      }
      return;
    };

    // #### Exit method
    // interrupts the execution flow of the current queue, resolving the promise
    this.exit = function() {
      // queue is breaking out
      // tell `next()` to return a falsey value
      shouldExitQueue = true;
    };

    // #### Skip method
    // sets a flag on the given task that tells the queue to ignore it.
    this.skip = function( task ) {
      if( !task ) {
        throw 'A task must be specified in order to skip';
      }

      task.skip = true;
    };

    // #### Run method
    // calls each tasks implementation in the queue, waiting for each tasks' promise
    // to be completed before moving on. If the task doesn't return a promise
    // it assumes a success and calls the next task immediately.
    this.run = function() {
      // instantiate a new Deferred object for this run
      deferred = $.Deferred();

      var queue = this,
          promise = queue.promise = deferred.promise();

      // set `shouldExitQueue` to `false` so that we can re-run the queue
      shouldExitQueue = false;

      // private method that will wait for a promise to be completed
      // or immediately execute a callback
      function waitfor(p, callback) {
        // check that we actually got a promise and
        // attach the callback and return the chain
        // otherwise, exectute the callback and return the result
        if( p && p.done ) {
          // if the promise succeeds then call our callback
          p.done(callback);

          // if the promise fails, reject our deferred with
          // any arguments the failed promise sends
          p.fail( deferred.reject );
        } else {
          callback();
        }
      }

      // private method to process the next task in the queue
      function exec() {
        var task =  !shouldExitQueue ? queue.next() : false;
        if( task ) {
          var result;

          if( !task.skip ) {
            // notify any attached listeners bound to `progress()` callbacks that we are starting
            // the next task
            deferred.notify( currentTask, queue.length, task );

            if( task.fn ) {
              // this is a targeted task, call it and wait for it to complete
              result = task.fn( task.target );
            } else {
              // this is a pipe or simple task
              // execute the task with previous/next arguments
              try {
                result = task.call(queue, queue.peek(-1), queue.peek(1) );
              } catch ( error ) {
                queue.trigger('run:fail');
                // if the task throws an exception then reject the current
                // deferred and exit the queue
                return deferred.reject( error, task );
              }
            }
          } else {
            // skip this task
            task.skip = false;
          }

          waitfor(result, exec);
        } else {
          // the queue has been processed
          // resolve the promise and signify
          // that work is complete
          deferred.resolve();

          queue.trigger('run:success');

          // increment our run count
          queue.runCount += 1;
        }
        return promise;
      }

      return exec();
    };

    // call initialize on child classes if applicable
    if( this.initialize ) {
      this.initialize.apply(this, arguments);
    }

    // load any functions passed in the constructor into the queue
    if( arguments.length > 0 ) {
      var coll = arguments;
      if( coll.length === 1 && coll[0].constructor === Array ) {
        coll = coll[0];
      }
      _.each(coll, _.bind(function(a) {
        this.then(a);
      }, this));
    }
  };

  // #### TaskQueue Instance Methods
  _.extend( PromiseQ.prototype, Backbone.Events, {
    // holds the promise for the current queue, assigned by `run()`
    promise: null,

    // the number of time the queue has been run successfully
    runCount: 0,

    // the length of the current queue
    length: 0
  });

  PromiseQ.extend = Backbone.Model.extend;

  Backbone.PromiseQ = PromiseQ;

  return Backbone.PromiseQ;
})
