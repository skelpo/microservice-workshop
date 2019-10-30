import JWTMiddleware
import Fluent
import Vapor

final class UsersController: RouteCollection {
    
    func boot(router: Router) {
        router.get("", use: profile)
        router.patch(EditUserInput.self, at: "", use: save)
        router.delete("", use: delete)
    }
    
    func profile(_ request: Request)throws -> Future<UserSuccessResponse> {
        return try request.user().response(on: request)
    }
    
    func save(_ request: Request, _ content: EditUserInput)throws -> Future<UserSuccessResponse> {
        let user = try request.user()
        
        if let firstname = content.firstname {
            user.firstname = firstname
        }
        if let lastname = content.lastname {
            user.lastname = lastname
        }
        
        return user.update(on: request).response(on: request)
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let user = try request.user()
        
        return try user.addresses(on: request).delete().transform(to: user).delete(on: request).transform(to: .noContent)
    }
}




