package db;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import jolie.runtime.FaultException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import org.bson.Document;
import org.bson.types.ObjectId;

public class MongoDBService extends JavaService {

    private MongoClient client;

    public Value connect( Value connectionInfo ) {
        client = MongoClients.create();
        return Value.create(true);
    }

    private void checkConnection() throws FaultException {
        if (client == null){
            throw new FaultException("NoConnection", "Not connected have u called Connect() first?");
        }
    }

    public Value insert( Value request ) throws FaultException {
        checkConnection();

        Document document;
        try {
            document = Document.parse( request.getFirstChild( "document" ).strValue() );
        }catch (Exception e){
            throw new FaultException("ParseException", e);
        }

        try {
            client.getDatabase( request.getFirstChild( "database" ).strValue() )
                    .getCollection( request.getFirstChild( "collection" ).strValue() )
                    .insertOne( document );
        }catch (Exception e){
            throw new FaultException("WriteException", e);
        }

        return Value.create(true);
    }

    public Value find( Value request ) throws FaultException {
        checkConnection();

        MongoCollection<Document> collection = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() );

        MongoCursor<Document> cursor = collection
                .find()
                .skip( request.firstChildOrDefault("offset", Value::intValue, v -> 0) )
                .limit( request.firstChildOrDefault("limit", Value::intValue, v -> 100) )
                .iterator();

        Value response = Value.create();
        response.getFirstChild( "count" ).setValue( (int) collection.estimatedDocumentCount() );

        if (!cursor.hasNext()){
            response.getFirstChild( "documents" ).setValue( "[]" );

            return response;
        }

        StringBuilder sb = new StringBuilder();
        sb.append("[");
        cursor.forEachRemaining(document -> sb.append( document.toJson() ).append( ',' ));
        sb.deleteCharAt(sb.length() - 1).append( ']' );

        response.getFirstChild( "documents" ).setValue( sb.toString() );
        return response;
    }

    public Value delete( Value request ) throws FaultException {
        checkConnection();

        MongoCollection<Document> collection = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() );

        boolean deleted = collection.deleteOne(new Document("_id", new ObjectId(request.getFirstChild( "id" ).strValue()))).getDeletedCount() > 0;
        return Value.create(deleted);
    }
}
