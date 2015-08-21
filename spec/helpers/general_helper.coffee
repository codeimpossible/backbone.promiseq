beforeEach () ->
  jasmine.DEFAULT_TIMEOUT_INTERVAL = 300
  jasmine.addMatchers
    toBeInstanceOf: (obj) -> @.actual instanceof obj
