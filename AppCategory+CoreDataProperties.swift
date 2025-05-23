//
//  AppCategory+CoreDataProperties.swift
//  myAcBook
//
//  Created by 한상욱 on 5/21/25.
//
//

import Foundation
import CoreData


extension AppCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppCategory> {
        return NSFetchRequest<AppCategory>(entityName: "Category")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var records: NSSet?

}

// MARK: Generated accessors for records
extension AppCategory {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: Record)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: Record)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}

extension AppCategory : Identifiable {

}
