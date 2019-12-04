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
  key: string
  value: string
}

type TextIndex: void {
  database: string
  collection: string
  unique: bool
  key: string
}

type Update: void {
  database: string
  collection: string
  key: string
  value: string
  document: string
}

type DocByValue: void {
  database: string
  collection: string
  key: string
  value: string
}

interface DocumentInterface {
  RequestResponse:
    connect( string )( bool ),
    createTextIndex( TextIndex )( void ),
    insert( Document )( bool ) throws WriteException( undefined ),
    find( Page )( PageResponse ),
    getByValue( DocByValue )( string ),
    delete( DeleteAction )( bool ),
    update( Update )( bool )
}

outputPort Database {
    Interfaces: DocumentInterface
}

embedded {
    Java: "db.MongoDBService" in Database
}
