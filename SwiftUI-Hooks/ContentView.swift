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


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    
    static var previews = ContentView()

}
#endif
