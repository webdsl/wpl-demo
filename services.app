module services

// for testing React applications locally, add to package.json:
// "proxy": "http://localhost:8080",
// this avoids CORS issues and enables using cookies for authentication


// service behaves similar to a page,
// the application responds to a URL starting with the service name.
// the difference is that service contains action/function code and returns JSON
// test with: curl http://localhost:8080/wpl-demo/users
service users(){
  // WebDSL built-in.app wraps JSONObject and JSONArray APIs
  // ctrl/cmd click on JSONArray/JSONObject in the editor to find this
  var a := JSONArray();
  for( t: TestService ){
    var o := JSONObject();
    o.put( "id", t.id );
    o.put( "name", t.name );
    o.put( "number", t.number );
    a.put( o );
  }
  return a;
}

// GET parameters can be provided in the URL with:
// servicename/arg1/arg2 or servicename?param1=arg1&param2=arg2
// test with: curl http://localhost:8080/wpl-demo/getUser/[insert one of the ids]
service getUser( user: TestService ){
  var o := JSONObject();
  o.put( "id", user.id );
  o.put( "name", user.name );
  o.put( "number", user.number );
  return o;
}

// POST data can be retrieved using readRequestBody()
// test with: curl -d '{"name":"WebDSL", "number":"42"}' -H "Content-Type: application/json" -X POST http://localhost:8080/wpl-demo/addUser
service addUser(){
  if( getHttpMethod() == "POST" ){
    var body := readRequestBody();
    var o := JSONObject( body );
    TestService{
      name := o.getString( "name" )
      number := o.getInt( "number" )
    }.save();
    var msgs := JSONArray();
    var msg := JSONObject();
    msg.put( "message", "ok" );
    msgs.put( msg );
    return msgs;
  }
}

// test with: curl -d '{"name":"WebDSL", "number":"42"}' -H "Content-Type: application/json" -X POST http://localhost:8080/wpl-demo/addUserValidate
// test with: curl -d '{"name":"12", "number":"-55"}' -H "Content-Type: application/json" -X POST http://localhost:8080/wpl-demo/addUserValidate
// test with: curl -d '{"name":"12", "number":"err"}' -H "Content-Type: application/json" -X POST http://localhost:8080/wpl-demo/addUserValidate
service addUserValidate(){
  if( getHttpMethod() == "POST" ){
    var body := readRequestBody();
    var o := JSONObject( body );
    var msgs := JSONArray();
    // need to check value wellformedness before trying to create entity
    if( o.getString( "number" ).parseInt() == null ){
      addJsonError( msgs, "number value is not a number" );
    } else {
      var ts := TestService{
        name := o.getString( "name" )
        number := o.getInt( "number" )
      }.save();
      // get the results from the entity validate checks
      var checkresults := ts.validateSave();
      for( ex in checkresults.exceptions ){
        // mark transaction to be aborted
        rollback();
        addJsonError( msgs, ex.message );
      }
      if( msgs.length() == 0 ){
        addJsonMessage( msgs, "ok" );
      }
    }
    return msgs;
  }
}

function addJsonError( msgs: JSONArray, error: String ){
  var o := JSONObject();
  o.put( "error", error );
  msgs.put( o );
}

function addJsonMessage( msgs: JSONArray, msg: String ){
  var o := JSONObject();
  o.put( "message", msg );
  msgs.put( o );
}

access control rules
  // use page rules for services
  rule page users(){ true }
  rule page addUser(){ true }
  rule page addUserValidate(){ true }
  rule page getUser( user: TestService ){ true }

section test data

entity TestService {
  name   : String  validate( name.length() > 3, "name too short" )
  number : Int     validate( number > 0, "number must be positive" )
}

// app init test data
init {
  for( i: Int from 0 to 10 ){
    TestService{ name := generateFirstName() number := i }.save();
  }
}

function generateFirstName: String {
  return [
    "Lisa"
  , "David"
  , "Laura"
  , "Lars"
  , "Julia"
  , "Stan"
  , "Anouk"
  , "Jesse"
  , "Nick"
  , "Naomi"
  , "Rick"
  , "Sarah"
  , "Daniel"
  , "Tessa"
  , "Sophie"
  , "Kevin"
  ].random();
}
