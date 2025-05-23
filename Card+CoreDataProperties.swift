//
//  Card+CoreDataProperties.swift
//  myAcBook
//
//  Created by 한상욱 on 5/21/25.
//
//

import Foundation
import CoreData


extension Card {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
        return NSFetchRequest<Card>(entityName: "Card")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var records: Record?

}

extension Card : Identifiable {

}
