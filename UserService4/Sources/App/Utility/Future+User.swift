import Vapor
import Fluent

extension EventLoopFuture where Value == User {
    func response(on database: Database) -> EventLoopFuture<UserSuccessResponse> {
        return self.flatMap { user in
            return user.response(on: database)
        }
    }
}

extension Request {
    func payload() throws -> JWTPayload {
        if let payload = self.jwtPayload {
            return payload
        }
        else {
            throw Abort(.badRequest)
        }
    }
    
    func user() throws -> EventLoopFuture<User> {
        let payload = try self.payload()
        
        return User.query(on: self.db).filter(\.$id == payload.id).first().flatMapThrowing { user in
            if let user = user {
                return user
            }
            else {
                throw Abort(.badRequest)
            }
        }
    }
}
