//
//  Record+CoreDataProperties.swift
//  myAcBook
//
//  Created by 한상욱 on 5/21/25.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var detail: String?
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var paymentType: String?
    @NSManaged public var card: Card?
    @NSManaged public var categoryRelation: AppCategory?

}

extension Record : Identifiable {

}
