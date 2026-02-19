public func configure<T>(_ object: T, using closure: (inout T) -> Void) -> T {
  var object = object
  closure(&object)
  return object
}
