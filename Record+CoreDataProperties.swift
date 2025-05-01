//
//  Record+CoreDataProperties.swift
//  myAcBook
//
//  Created by 한상욱 on 4/28/25.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var detail: String?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var type: String? // ✨ 새로 추가해야 함
}

extension Record : Identifiable {

}
