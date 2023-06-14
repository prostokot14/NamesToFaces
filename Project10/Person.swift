//
//  Person.swift
//  Project10
//
//  Created by Антон Кашников on 14.06.2023.
//

import ObjectiveC

final class Person: NSObject {
    var name: String
    var image: String

    init(name: String, image: String) {
        self.name = name
        self.image = image
    }
}
