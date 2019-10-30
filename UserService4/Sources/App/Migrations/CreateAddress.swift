import Fluent


struct CreateAddress: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("addresses")
            .field("id", .int, .identifier(auto: true))
            .field("street", .string, .required)
            .field("city", .string, .required)
            .field("zip", .string, .required)
            .field("userId", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("addresses").delete()
    }
}
