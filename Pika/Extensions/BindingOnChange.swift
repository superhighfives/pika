import SwiftUI

extension Binding {
    func onChange(perform: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: {
            // return wrapped value
            self.wrappedValue
        }, set: { newValue in
            // set new value
            self.wrappedValue = newValue
            // call completion
            perform(newValue)
        })
    }

    func onChange(perform: @escaping () -> Void) -> Binding<Value> {
        Binding(get: {
            // return wrapped value
            self.wrappedValue
        }, set: { newValue in
            // set new value
            self.wrappedValue = newValue
            // call completion
            perform()
        })
    }
}
