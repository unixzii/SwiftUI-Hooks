#  SwiftUI Hooks

> Note: This is only a proof of concept, not for production use yet.

## Quick Start

```swift
let ContentView = { RendererView { hooks in
    let (counter, setCounter) = hooks.useState(initial: 0)
    hooks.useEffect {
        if counter == 5 {
            alert("High five!")
        }
    }
    hooks.useEffect({
        alert("Hi there!")
    }, dep: RendererView.triggerOnce)

    return VStack {
        Text("Current value: \(counter)")
        HStack {
            Button(action: { setCounter(counter + 1) }) { Text("+") }
            Button(action: { setCounter(counter - 1) }) { Text("-") }
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)>*
} }
```

## Prior Art

This is fully inspired by [React Hooks](https://reactjs.org/docs/hooks-intro.html). To learn more about what hooks are doing, please first check out the React documentation. And the API design in this PoC also follows the React spec, you can literally map what you learned to this.

## API References

*TBD.*

See [RendererView.swift](https://github.com/unixzii/SwiftUI-Hooks/blob/master/SwiftUI-Hooks/RendererView.swift#L12).

## Todos

- [ ] `useEffect` with cleanup.
- [ ] Detection of inconsistent hook calls.
- [ ] ...

## Contribution

This repository won't accept PRs about detail design. If you are interested in making it a library, feel free to leave an issue and let me know.
