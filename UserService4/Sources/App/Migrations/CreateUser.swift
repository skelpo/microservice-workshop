import Fluent


struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .field("id", .int, .identifier(auto: true))
            .field("firstname", .string, .required)
            .field("lastname", .string, .required)
            .field("email", .string, .required)
            .field("password", .string, .required)
            .field("createdAt", .date)
            .field("updatedAt", .date)
            .field("deletedAt", .date)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
