package db;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import com.mongodb.client.result.DeleteResult;
import com.mongodb.client.result.UpdateResult;
import jolie.runtime.FaultException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import org.bson.Document;
import org.bson.types.ObjectId;

import static com.mongodb.client.model.Filters.eq;

public class MongoDBService extends JavaService {

    private MongoClient client;

    public Value connect( Value connectionInfo ) {
        if (connectionInfo.strValue().equals("")){
            client = MongoClients.create();
        }else{
            client = MongoClients.create( connectionInfo.strValue() );
        }
        return Value.create(true);
    }

    private void checkConnection() throws FaultException {
        if (client == null){
            throw new FaultException("NoConnection", "Not connected have u called Connect() first?");
        }
    }

    public void createTextIndex( Value request ){
        IndexOptions indexOptions = new IndexOptions().unique( request.getFirstChild( "unique" ).boolValue() );

        client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() )
                .createIndex( Indexes.text(request.getFirstChild( "key" ).strValue()), indexOptions );
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

    public Value update( Value request ) throws FaultException {
        checkConnection();
        UpdateResult updateResult = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() )
                .updateOne( eq(request.getFirstChild( "key" ).strValue(), request.getFirstChild( "value" ).strValue()), new Document("$set", Document.parse( request.getFirstChild( "document" ).strValue() )));
        return Value.create( updateResult.getModifiedCount() > 0 );
    }

    public Value find( Value request ) throws FaultException {
        checkConnection();

        MongoCollection<Document> collection = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() );

        MongoCursor<Document> cursor = collection
                .find()
                .skip( request.firstChildOrDefault("offset", Value::intValue, v -> 0) )
                .limit( request.getFirstChild( "limit" ).intValue() )
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

    public Value getByValue( Value request ) throws FaultException {
        checkConnection();

        MongoCollection<Document> collection = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() );

        Document d = collection.find(eq(request.getFirstChild( "key" ).strValue() ,request.getFirstChild( "value" ).strValue() )).first();

        if ( d == null){
            throw new FaultException("NotFound");
        }

        return Value.create(d.toJson());
    }

    public Value delete( Value request ) throws FaultException {
        checkConnection();

        DeleteResult deleteResult = client.getDatabase( request.getFirstChild( "database" ).strValue() )
                .getCollection( request.getFirstChild( "collection" ).strValue() ).deleteOne(eq(request.getFirstChild( "key" ).strValue(), request.getFirstChild( "value" ).strValue()));;

        return Value.create( deleteResult.getDeletedCount() > 0 );
    }
}
