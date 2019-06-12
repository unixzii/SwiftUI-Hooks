//
//  ContentView.swift
//  SwiftUI-Hooks
//
//  Created by Hongyu on 6/12/19.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import SwiftUI

func alert(_ message: String) {
    let anAlert = NSAlert()
    anAlert.messageText = message
    anAlert.beginSheetModal(for: NSApp.keyWindow!, completionHandler: nil)
}

func bindingFromUseState<S>(_ useStateTuple: (S, (S) -> ())) -> Binding<S> {
    return Binding(getValue: {
        return useStateTuple.0
    }, setValue: {
        useStateTuple.1($0)
    })
}

struct TodoItem : Identifiable {
    var id: Int
    var content: String
    var done: Bool
}

enum TodoAction {
    case add(String)
    case edit(Int, String, Bool)
    case delete(Int)
    case clearDone
}

let TodoItemView = { (item: TodoItem, dispatch: @escaping (TodoAction) -> ()) in
    RendererView { hook in
        return HStack(alignment: .center, spacing: 6) {
            Toggle(isOn: Binding<Bool>(getValue: {
                return item.done
            }, setValue: {
                dispatch(.edit(item.id, item.content, $0))
            })) { EmptyView() }
            .fixedSize()
            
            Text(item.content)
            
            Spacer()
            
            Button(action: {
                dispatch(.delete(item.id))
            }) { Text("X") }
        }>*
    }
}

let ContentView = { RendererView { hooks in
    let (nextId, setNextId) = hooks.useState(initial: 0)
    let newTodoContent = hooks.useState(initial: "")
    let (todos, dispatch) = hooks.useReducer({ (state, action: TodoAction) in
        switch action {
        case .add(let content):
            if content.isEmpty {
                return state
            }
            
            var newState = state
            newState.insert(TodoItem(id: nextId, content: content, done: false), at: 0)
            setNextId(nextId + 1)
            return newState
            
        case .edit(let id, let content, let done):
            guard let indexToEdit = state.firstIndex(where: { $0.id == id }) else {
                return state
            }
            var itemToEdit = state[indexToEdit]
            itemToEdit.content = content
            itemToEdit.done = done
            var newState = state
            newState[indexToEdit] = itemToEdit
            return newState
            
        case .delete(let id):
            return state.filter { $0.id != id }
            
        case .clearDone:
            return state.filter { !$0.done }
        }
    }, initial: [TodoItem]())
    
    let totalLeft = todos.count - todos.map({ $0.done ? 1 : 0 }).reduce(0) { $0 + $1 }
    
    return VStack {
        TextField(bindingFromUseState(newTodoContent),
                  placeholder: Text("What needs to be done?"),
                  onEditingChanged: { _ in }) {
            dispatch(.add(newTodoContent.0))
            newTodoContent.1("")
        }
        
        List {
            ForEach(todos) {
                TodoItemView($0, dispatch)
            }
        }
        
        HStack {
            Text("\(totalLeft)")
                .bold()
            + Text(" \(totalLeft == 1 ? "item" : "items") left.")
            
            Spacer()
            
            Button(action: {
                dispatch(.clearDone)
            }) { Text("Clear Done") }
        }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)>*
} }


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    
    static var previews = ContentView()

}
#endif
