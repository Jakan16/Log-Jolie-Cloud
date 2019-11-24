type ConnectionInfo: void

type Document: void {
  database: string
  collection: string
  document: string
}

interface DocumentInterface {
  RequestResponse:
    connect( ConnectionInfo )( bool ),
    insert( Document )( bool )
}

outputPort Database {
    Interfaces: DocumentInterface
}

embedded {
    Java: "db.MongoDBService" in Database
}
