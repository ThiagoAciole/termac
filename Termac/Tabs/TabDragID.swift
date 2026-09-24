//
//  TabDragID.swift
//  termac
//

import CoreTransferable
import UniformTypeIdentifiers

struct TabDragID: Codable, Transferable {
    let id: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}
