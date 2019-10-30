import Fluent
import Vapor

final class AddressesController: RouteCollection {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("", use: addresses)
        routes.post(use: create)
        routes.patch(":id", use: update)
        routes.delete(":id", use: delete)
    }
    
    
    
    func addresses(_ request: Request)throws -> EventLoopFuture<[Address]> {
        let payload = try request.payload()
        
        return Address.query(on: request.db).filter(\Address.$userId == payload.id).all()
    }
    
    func create(_ request: Request)throws -> EventLoopFuture<AddressSuccessResponse> {
        
        let content = try request.content.decode(AddressInput.self)
        
        let payload = try request.payload()
        
        let address = Address(street: content.street, city: content.city, zip: content.zip, userId: payload.id)
        
        return address.save(on: request.db).map {_ in 
            return AddressSuccessResponse(address: AddressResponse(street: address.street, city: address.city, zip: address.zip))
        }
    }
    
    func update(_ request: Request)throws -> EventLoopFuture<AddressSuccessResponse> {
        let content = try request.content.decode(AddressInput.self)
        
        let payload = try request.payload()
        
        let id:Int? = request.parameters.get("id")
        
        return Address.query(on: request.db).filter(\Address.$id == id).filter(\Address.$userId == payload.id).all().flatMap { addresses in
            
            if addresses.count == 0 {
                return request.eventLoop.future(error: Abort(.badRequest, reason: "No address found!"))
            }
            let address = addresses.first!
            address.street = content.street
            address.city = content.city
            address.zip = content.zip
            
            return address.save(on: request.db).map {
                return AddressSuccessResponse(address: AddressResponse(street: address.street, city: address.city, zip: address.zip))
            }
        }
    }
    
    func delete(_ request: Request)throws -> EventLoopFuture<HTTPStatus> {
        let payload = try request.payload()
        
        let id:Int? = request.parameters.get("id")
        
        return Address.query(on: request.db).filter(\.$id == id).filter(\.$userId == payload.id).all().flatMap { addresses in
            if addresses.count == 0 {
                return request.eventLoop.future(error: Abort(.badRequest, reason: "No address found!"))
            }
            return addresses.first!.delete(on: request.db).transform(to: HTTPResponseStatus.ok)
        }
    }
}




