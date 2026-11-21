
import Foundation
import FirebaseFirestore

struct VenueDTO {
    let id: String
    let ownerUid: String
    let name: String
    let address: String
    let photoUrl: String
    let createdAt: Timestamp

    init(
        id: String,
        ownerUid: String,
        name: String,
        address: String,
        photoUrl: String,
        createdAt: Timestamp = Timestamp(date: Date())
    ) {
        self.id = id
        self.ownerUid = ownerUid
        self.name = name
        self.address = address
        self.photoUrl = photoUrl
        self.createdAt = createdAt
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let ownerUid = data["ownerUid"] as? String,
              let name = data["name"] as? String else {
            return nil
        }

        self.id = document.documentID
        self.ownerUid = ownerUid
        self.name = name
        self.address = (data["address"] as? String) ?? ""
        self.photoUrl = (data["photoUrl"] as? String) ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp) ?? Timestamp(date: Date())
    }

    func toFirestoreCreateData() -> [String: Any] {
        [
            "ownerUid": ownerUid,
            "name": name,
            "address": address,
            "photoUrl": photoUrl,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }

    func toFirestoreUpdateData() -> [String: Any] {
        [
            "name": name,
            "address": address,
            "photoUrl": photoUrl
        ]
    }

    func toDomain() -> Venue {
        Venue(
            id: id,
            ownerUid: ownerUid,
            name: name,
            address: address,
            photoUrl: photoUrl,
            createdAt: createdAt.dateValue()
        )
    }
}
