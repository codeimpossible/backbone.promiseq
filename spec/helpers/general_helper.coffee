beforeEach () ->
  @.addMatchers
    toBeInstanceOf: (obj) -> @.actual instanceof obj