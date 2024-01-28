@testable import Mappable
import XCTest

final class MappableTests: XCTestCase {
    func testMappingFromModel() {
        let user = User(
            id: .init(value: 1),
            firstName: "John",
            lastName: "Doe",
            bio: "Lorem ipsum",
            age: 35
        )

        let userModel = UserModel(model: user)

        XCTAssertEqual(
            userModel,
            .init(
                id: 1,
                firstName: "John",
                lastName: "DOE",
                biography: "Lorem ipsum",
                dateOfBirth: Date(age: 35)
            )
        )
    }

    func testMappingToModel() {
        let userModel = UserModel(
            id: 1,
            firstName: "John",
            lastName: "DOE",
            biography: "Lorem ipsum",
            dateOfBirth: Date(age: 35)
        )

        let user = userModel.model()

        XCTAssertEqual(
            user,
            .init(
                id: .init(value: 1),
                firstName: "John",
                lastName: "Doe",
                bio: "Lorem ipsum",
                age: 35
            )
        )
    }
}

// MARK: SUT

private struct Identifier {
    let value: Int
}

private struct User {
    let id: Identifier
    let firstName: String
    let lastName: String
    let bio: String
    let age: Int
}

@Mappable(to: User.self)
private class UserModel {
    @Map(from: \.value, to: Identifier.init(value:))
    private let id: Int
    private let firstName: String
    @Map(from: { (lastName: String) -> String in lastName.uppercased() }, to: { $0.lowercased().capitalized })
    private let lastName: String
    @Map("bio")
    private let biography: String
    @Map(
        "age",
        from: {
            let date = Date(age: $0)
            return date
        },
        to: {
            $0.age
        }
    )
    private let dateOfBirth: Date

    init(id: Int, firstName: String, lastName: String, biography: String, dateOfBirth: Date) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.biography = biography
        self.dateOfBirth = dateOfBirth
    }
}

extension Identifier: Equatable {}

extension User: Equatable {}

extension UserModel: Equatable {
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.biography == rhs.biography &&
        lhs.dateOfBirth == rhs.dateOfBirth
    }
}

// MARK: Extensions

extension Date {
    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year!
    }

    init(age: Int) {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: .now) - age
        var dateComponents = DateComponents()
        dateComponents.year = birthYear
        self = calendar.date(from: dateComponents)!
    }
}
