//
//  msg2barkApp.swift
//  msg2bark
//
//  Created by 王立程 on 2024/11/12.
//

import SwiftUI

@main
struct msg2barkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
