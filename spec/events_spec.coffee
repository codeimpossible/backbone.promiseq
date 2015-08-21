# global console, runs, waits
describe "Events", ->
  queue = undefined
  simpleTask = ->
    console.log "testing"

  nextTask = ->
    console.log "something"

  beforeEach ->
    queue = new Backbone.PromiseQ

  it "should extend the Backbone.Events object", ->
    expect(queue.on).toBeDefined()
    expect(queue.trigger).toBeDefined()
    expect(queue.off).toBeDefined()

  it "should trigger run:success when the queue completes", (done) ->
    result = false

    queue.on 'run:success', ->
      result = true
      expect(result).toBe true
      done()

    queue.run()

  it "should trigger run:fail when the queue errors out", (done) ->
    result = true
    queue.then ->
      throw "error!"

    queue.on 'run:fail', ->
      result = false
      expect(result).toBe false
      done()
    queue.run()
