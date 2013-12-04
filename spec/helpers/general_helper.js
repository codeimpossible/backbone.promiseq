beforeEach(function() {
  return this.addMatchers({
    toBeInstanceOf: function(obj) {
      return this.actual instanceof obj;
    }
  });
});
