type ConnectionInfo: void

type Document: void {
  database: string
  collection: string
  document: string
}

type Page: void {
  database: string
  collection: string
  limit?: int
  offset?: int
}

type PageResponse: void {
  documents: string
  count: int
}

type DeleteAction: void {
  database: string
  collection: string
  id: string
}

interface DocumentInterface {
  RequestResponse:
    connect( ConnectionInfo )( bool ),
    insert( Document )( bool ),
    find( Page )( PageResponse ),
    delete( DeleteAction )( bool )
}

outputPort Database {
    Interfaces: DocumentInterface
}

embedded {
    Java: "db.MongoDBService" in Database
}
