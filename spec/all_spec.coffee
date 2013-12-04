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
    queue.enqueue simpleTask
    expect(queue.length).toBe 1
    expect(queue.at(0)).toBe simpleTask

  describe "enqueue", ->
    it "should return the queue instance for chaining", ->
      result = queue.enqueue(simpleTask)
      expect(result).toBe queue

    it "should allow a pipe task to be added to the queue", ->
      project = new Backbone.Model()
      queue.enqueue project, (project) ->
        project.set "something", "test"

      expect(queue.length).toBe 1
      expect(queue.at(0).target).toBe project
      expect(queue.at(0).fn).toBeInstanceOf Function


  describe "next", ->
    describe "with no previous task", ->
      it "should return the next item in the queue", ->
        queue.enqueue(simpleTask).enqueue nextTask
        expect(queue.next()).toBe simpleTask


    describe "previous task", ->
      it "should return the next item in the queue", ->
        queue.enqueue(simpleTask).enqueue nextTask
        queue.next()
        expect(queue.next()).toBe nextTask


    describe "with no more tasks", ->
      it "should return undefined", ->
        queue.enqueue(simpleTask).enqueue nextTask
        queue.next()
        queue.next()
        expect(queue.next()).toBeUndefined()



  describe "run", ->
    describe "when an error ocurrs", ->
      it "should reject the promise", ->
        result = true
        queue.enqueue ->
          throw "error!"

        runs ->
          queue.run().fail ->
            result = false


        waits 100
        runs ->
          expect(result).toBe false



    describe "when complete", ->
      it "should resolve the promise", ->
        result = false
        runs ->
          queue.run().then ->
            result = true


        waits 500
        runs ->
          expect(result).toBe true



    describe "when running tasks", ->
      it "should run them in order", ->
        ref = num: 0
        runs ->
          queue.enqueue(ref, (r) ->
            r.num = 1
          ).enqueue(->
            expect(ref.num).toBe 1
          ).enqueue(ref, (r) ->
            r.num = 3
          ).enqueue ->
            expect(ref.num).toBe 3


        runs ->
          queue.run()

        waits 500



  describe "exit", ->
    num = 0
    beforeEach ->
      num = 0
      queue.enqueue(->
        num += 1
      ).enqueue(->
        @exit()  if num is 1
      ).enqueue ->
        num += 1


    it "should short-circuit a task queue run immediately", ->
      runs ->
        queue.run()

      waits 300
      runs ->
        expect(num).toBe 1


    describe "when called before the queue is run", ->
      it "should have no effect on the queue", ->
        runs ->
          queue.exit()
          queue.run()

          # should be a no-op
          expect(num).toBe 1




  describe "skip", ->
    num = 0
    beforeEach ->
      num = 0
      queue.enqueue(->
        num += 1
      ).enqueue((previous, next) ->
        @skip next
      ).enqueue(->
        num += 1
      ).enqueue ->
        num += 1


    it "can be called before the queue is run", ->
      runs ->
        queue.skip queue.at(3)
        queue.run()

      waits 300
      runs ->
        expect(num).toBe 1


    it "should skip the task passed", ->
      runs ->
        queue.run()

      waits 300
      runs ->
        expect(num).toBe 2



