
import Foundation
import FirebaseFirestore

struct AuthDTO {
    let uid: String
    let fullName: String
    let email: String
    let role: String
    let createdAt: Timestamp

    init(uid: String, fullName: String, email: String, role: UserRole, createdAt: Timestamp = Timestamp(date: Date())) {
        self.uid = uid
        self.fullName = fullName
        self.email = email
        self.role = role.rawValue
        self.createdAt = createdAt
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        let uid = (data["uid"] as? String) ?? document.documentID
        let fullName = (data["fullName"] as? String) ?? ""
        let email = (data["email"] as? String) ?? ""
        let role = (data["role"] as? String)?.lowercased() ?? UserRole.customer.rawValue
        let createdAt = (data["createdAt"] as? Timestamp) ?? Timestamp(date: Date())

        self.uid = uid
        self.fullName = fullName
        self.email = email
        self.role = role
        self.createdAt = createdAt
    }

    func toFirestoreData() -> [String: Any] {
        [
            "uid": uid,
            "fullName": fullName,
            "email": email,
            "role": role.lowercased(),
            "createdAt": FieldValue.serverTimestamp()
        ]
    }

    func toDomain() -> User {
        User(
            id: uid,
            fullName: fullName.isEmpty ? "Пользователь" : fullName,
            email: email,
            role: UserRole(rawValue: role.lowercased()) ?? .customer,
            createdAt: createdAt.dateValue()
        )
    }
}
