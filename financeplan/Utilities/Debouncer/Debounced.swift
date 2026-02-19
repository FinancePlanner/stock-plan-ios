import Combine
import SwiftUI

@propertyWrapper
struct Debounced<T>: DynamicProperty {
  @StateObject var debouncer: Debouncer<T>

  init(
    wrappedValue: T,
    for dueTime: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.4),
    scheduler: DispatchQueue = DispatchQueue.main
  ) {
    let debouncer = Debouncer(value: wrappedValue, for: dueTime, scheduler: scheduler)
    _debouncer = StateObject(wrappedValue: debouncer)
  }

  var wrappedValue: T {
    get { debouncer.debouncedValue }
    nonmutating set { debouncer.update(newValue) }
  }

  var projectedValue: Binding<T> {
    Binding {
      debouncer.value
    } set: {
      debouncer.update($0)
    }
  }
}
