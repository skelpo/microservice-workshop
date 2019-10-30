import Fluent
import Vapor
import Fluent

final class UsersController: RouteCollection {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
        
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: profile)
        routes.patch(use: save)
        routes.delete(use: delete)
    }
    
    func profile(_ request: Request)throws -> EventLoopFuture<UserSuccessResponse> {
        return try request.user().response(on: request.db)
    }
    
    func save(_ request: Request)throws -> EventLoopFuture<UserSuccessResponse> {
        
        let content = try request.content.decode(EditUserInput.self)
        
        return try request.user().flatMap { user in
            if let firstname = content.firstname {
                user.firstname = firstname
            }
            if let lastname = content.lastname {
                user.lastname = lastname
            }
            
            return user.update(on: request.db).transform(to: user).response(on: request.db)
        }
        
        
    }
    
    func delete(_ request: Request)throws -> EventLoopFuture<HTTPStatus> {
        return try request.user().flatMap { user in
            return user.addresses(on: request.db)!.delete().transform(to: user)
        }.flatMap { user in
            return user.delete(on: request.db).transform(to: .noContent)
        }
    }
}




