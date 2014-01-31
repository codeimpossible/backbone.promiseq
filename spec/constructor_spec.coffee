# global console, runs, waits
describe "Constructor", ->
  queue = undefined
  simpleTask = ->
    console.log "testing"

  nextTask = ->
    console.log "something"

  it "should accept promises and add them to the queue", ->
    q = new Backbone.PromiseQ simpleTask, nextTask
    expect(q.length).toBe 2
    expect(q.at(0)).toBe simpleTask
    expect(q.at(1)).toBe nextTask

  it "should accept an array of promises", ->
    q = new Backbone.PromiseQ [simpleTask, nextTask]
    expect(q.length).toBe 2
    expect(q.at(0)).toBe simpleTask
    expect(q.at(1)).toBe nextTask
