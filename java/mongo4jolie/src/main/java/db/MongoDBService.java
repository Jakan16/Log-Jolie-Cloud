package db;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import jolie.runtime.FaultException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import org.bson.Document;

public class MongoDBService extends JavaService {

    private MongoClient client;

    public Value connect( Value connectionInfo ) {
        client = MongoClients.create();
        return Value.create(true);
    }

    public Value insert( Value request ) throws FaultException {
        if (client == null){
            throw new FaultException("NoConnection", "Not connected have u called Connect() first?");
        }

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

}
