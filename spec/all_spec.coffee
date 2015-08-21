# global console, runs, waits
describe "TaskQueue", ->
  queue = undefined
  simpleTask = ->
    console.log "testing"

  nextTask = ->
    console.log "something"

  beforeEach ->
    queue = new Backbone.PromiseQ()

  it "should be a class", ->
    expect(queue).toBeDefined()

  it "should allow a function to be added to the queue", ->
    queue.then simpleTask
    expect(queue.length).toBe 1
    expect(queue.at(0)).toBe simpleTask

  describe "then", ->
    it "should return the queue instance for chaining", ->
      result = queue.then(simpleTask)
      expect(result).toBe queue

    it "should allow a pipe task to be added to the queue", ->
      project = new Backbone.Model()
      queue.then project, (project) ->
        project.set "something", "test"

      expect(queue.length).toBe 1
      expect(queue.at(0).target).toBe project
      expect(queue.at(0).fn instanceof Function).toBe true


  describe "next", ->
    describe "with no previous task", ->
      it "should return the next item in the queue", ->
        queue.then(simpleTask).then nextTask
        expect(queue.next()).toBe simpleTask


    describe "previous task", ->
      it "should return the next item in the queue", ->
        queue.then(simpleTask).then nextTask
        queue.next()
        expect(queue.next()).toBe nextTask


    describe "with no more tasks", ->
      it "should return undefined", ->
        queue.then(simpleTask).then nextTask
        queue.next()
        queue.next()
        expect(queue.next()).toBeUndefined()



  describe "run", ->
    describe "when an error ocurrs", ->
      it "should reject the promise", (done) ->
        result = true
        queue.then ->
          throw "error!"

        queue.run().fail ->
          result = false
          expect(result).toBe false
          done()

    describe "when complete", ->
      it "should resolve the promise", (done) ->
        result = false

        queue.run().then ->
          result = true
          expect(result).toBe true
          done()


    describe "when running tasks", ->
      it "should run them in order", (done) ->
        ref = num: 0
        queue.then(ref, (r) ->
          r.num = 1
        ).then(->
          expect(ref.num).toBe 1
        ).then(ref, (r) ->
          r.num = 3
        ).then ->
          expect(ref.num).toBe 3
          done();

        queue.run()


  describe "exit", ->
    num = 0
    beforeEach ->
      num = 0
      queue.then(->
        num += 1
      ).then(->
        @exit()  if num is 1
      ).then ->
        num += 1


    it "should short-circuit a task queue run immediately", (done) ->
      queue.on 'run:success', ->
        expect(num).toBe 1
        done()

      queue.run()

    describe "when called before the queue is run", ->
      it "should have no effect on the queue", (done) ->
        queue.exit()
        queue.on 'run:success', ->
          expect(num).toBe 1
          done()
        queue.run()

  describe "skip", ->
    num = 0
    beforeEach ->
      num = 0
      queue.then(->
        num += 1
      ).then((previous, next) ->
        @skip next
      ).then(->
        num += 1
      ).then ->
        num += 1


    it "can be called before the queue is run", (done) ->
      queue.skip queue.at(3)
      queue.then ->
        expect(num).toBe 1
        done()
      queue.run()

    it "should skip the task passed", (done) ->
      queue.then ->
        expect(num).toBe 2
        done()
      queue.run()
