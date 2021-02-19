application wpldemo

page root {
  navigate overrideTest(){ "override test" }
  navigate types() { "types" }
  navigate bidirectional(){ "bidirectional relation" }
  navigate typesWithStyling() { "types with styling" }
  navigate testExpressions() { "expressions" }
  navigate dataValidation(){ "data validation" }
  navigate testSession() { "session entity" }
  navigate accessControl(){ "access control" }
  navigate url( navigate( emailTest() ) + "?nocache" ){ "email" }
  navigate ajaxTest(){ "ajax templates" }
  navigate ajaxPartialPageRefresh(){ "ajax partial page refresh" }
}


section template override

imports imported

override template one {
  "1!!"
}

page overrideTest {
  one
  showLocalOverride
}

template showLocalOverride {
  one
  stillLocalOverride
  template one { "local" }  // local override
}

template stillLocalOverride {
  one
}


section ajax templates

ajax template ajaxPersonEdit( p: Person, ph: Placeholder ){
  form {
    input( p.name )
    submitlink action {
      replace( ph, ajaxPersonView(p) );
    }{ "save" }
  }
}

ajax template ajaxPersonView( p: Person ){
  output( p.name )
}

ajax template ajaxItem( i: Item ){
  output( i.name )
}

page ajaxTest {
  var i := (from Item)[0]
  var p := (from Person)[0]
  placeholder ph { ajaxItem( i ) }
  submitlink action {
    replace( ph, ajaxPersonEdit( p, ph ) );
  }{ "edit" }
}

access control rules
  rule ajaxtemplate ajaxPersonEdit( p: Person, ph: Placeholder ){ true }
  rule ajaxtemplate ajaxPersonView( p: Person ){ true }
  rule ajaxtemplate ajaxItem( i: Item ){ true }


section ajax partial page refresh

entity TestInvoke {
  i: Int
}

var globalTestInvoke := TestInvoke { i := 0 }

page ajaxPartialPageRefresh {
  placeholder page {
    div{ output( globalTestInvoke.i ) }
  }
  submitlink action {
    globalTestInvoke.i := globalTestInvoke.i + 1;
    replace( page );
  }{ "add 1" }
  autoRefreshPlaceholder( page )
  navigate root() { "root" }
}

invoke updateTestInvoke() every 20 seconds

function updateTestInvoke {
  globalTestInvoke.i := globalTestInvoke.i + 100;
}

// auto refresh every second
template autoRefreshPlaceholder( ph: Placeholder ){
  submitlink
    action{ replace( ph ); }
    [ id= "refresh", style= "display:none;" ]{ "refresh" }
  <script>
    var refreshtimer;
    function setRefreshTimer(){
      clearTimeout(refreshtimer);
      refreshtimer = setTimeout(function() {
        $("#refresh").click();
        setRefreshTimer();
      },1000);
    }
    setRefreshTimer();
  </script>
}


section email

entity Person {
  name  : String
  email : String
}

init {
  Person{ name := "test" email := "test@example.com" }.save();
}

function notifyPersons {
  for( p: Person ){
    email notify( p, from Student );
  }
}

email notify( p: Person, students : [Student] ){
  subject( "awaiting review" )
  to( p.email )
  from( "noreply@example.com" )
  "Hello ~p.name, the following students have submitted:"
  for( s in students ){
    div {
      output( s.name )
    }
  }
  br
  "Go to " navigate root(){ "website" }
}

page emailTest {
  submit action{ notifyPersons(); }{ "notify" }
  div{ "debug email in queue (use ?nocache to avoid page cache from hiding them)" }
  div{ "emails are first stored in database, if there is no smtp server setup, they will stay there" }
  table {
    for( q: QueuedEmail ){
      // old built-in webdsl feature, still useful for quick dump of properties 
      derive viewRows from q
    }
  }
}


section bidirectional

entity Course {
  name     : String
  students : {Student}
  lecturer : Staff
}

entity Student {
  name    : String
  following : {Course} ( inverse= students )
}

entity Staff {
  name     : String
  teaching : {Course} ( inverse= lecturer )
}

init {
  Student{ name := "student1" }.save();
  Student{ name := "student2" }.save();
  Staff{ name := "staff1" }.save();
  Staff{ name := "staff2" }.save();
  Course{ name := "course1" }.save();
  Course{ name := "course2" }.save();
}

page bidirectional {
  for( s: Staff ){
    form {
      output( s.name )
      input( s.teaching )
      submit action{} { "save" }
    }
  }
  for( s: Student ){
    form {
      output( s.name )
      input( s.following )
      submit action{} { "save" }
    }
  }
  for( c: Course ){
    h3 { output( c.name ) }
    div { "lecturer: ~c.lecturer.name" }
    div { "students: " }
    div {
      output( [ s.name | s in c.students ].concat( ", " ) )
    }
  }
}


section authentication and access control

entity User {
  username : String (name)
  password : Secret
  wants    : {Item}  // instead of session entity
}

principal is User with credentials username, password

access control rules
  rule page root{ true }
  rule page *(*){ true }
  rule page loggedInPage{ loggedIn() }
  rule template loggedInTemplate{ loggedIn() }
section

page accessControl {
  authentication
  if( loggedIn() ){
    "logged in as: ~securityContext.principal.username"
  }
  loggedInTemplate
  h3{ "registration" }
  var newuser := User{}
  form {
    input( newuser.username )
    input( newuser.password )
    submit action{
      newuser.password := newuser.password.digest();
      newuser.save();
    }{ "save" }
  }
  navigate loggedInPage(){ "go to logged in page" }
}

page loggedInPage {
  "you are logged in (page)"
}

template loggedInTemplate {
  div{ "you are logged in (template)" }
}


section access control customization

override template authentication {
  if( loggedIn() ){
    logout()
  }
  else{
    login()
  }
}

override template logout {
  if( securityContext.principal != null ){
    "Logged in as: " output( securityContext.principal.name )
  }
  form {
    submitlink signoffAction(){ "Logout" }
  }
  action signoffAction() {
    logout();
  }
}

override template login {
  var username : String
  var password : Secret
  var stayLoggedIn := false
  form {
    <fieldset>
    <legend>
      output( "Login" )
    </legend>
    <table>
      <tr>labelcolumns( "Username:" ){ input( username ) }</tr>
      <tr>labelcolumns( "Password:" ){ input( password ) }</tr>
      <tr>labelcolumns( "Stay logged in:" ){ input( stayLoggedIn ) }</tr>
    </table>
    submit signinAction() { "Login" }
    </fieldset>
  }
  action signinAction {
    getSessionManager().stayLoggedIn := stayLoggedIn;
    validate( authenticate( username, password )
            , "The login credentials are not valid." );
    message( "You are now logged in." );
    return root();
  }
}


section data validation

entity CheckThis {
  i : Int (validate( i > 0, "must be greater than 0" ))
  s : String
}

page dataValidation {
  var c := CheckThis{}
  var i : Int
  main {
    form {
      input( "template var int", i )
      input( "int value", c.i )
      input( "string value", c.s ){
        validate( c.s.length() > 2, "too short" )
      }
      validate( (from CheckThis).length < 2, "max number saved" )
      centerRow {
        submitlink action{
          validate( i > 0, "template var < 0" );
          c.save();
        }[ class="col-sm-4" ]{ "Save" }
      }
      centerRow {
        div[ class="col-sm-4" ]{
          "number saved: ~((from CheckThis).length)"
        }
      }
    }
  }
}

template centerRow {
  <div class="row justify-content-md-center ">
    elements
  </div>
}


section data validation styling

override template errorTemplateInput( messages: [String] ){
  elements
  for( ve in messages ){
    div[ class="row justify-content-md-center" ]{
      div[ class= "col-sm-2" ]
      div[ class= "col-sm-2" ]{
        span[ style := "color: #FF0000" ]{
          text(ve)
        }
      }
    }
  }
}

override template errorTemplateForm( messages: [String] ){
  elements
  for( ve in messages ){
    div[ class="row justify-content-md-center" ]{
      div[ class= "col-sm-2" ]
      div[ class= "col-sm-2" ]{
        span[ style := "color: #FF0000" ]{
          text(ve)
        }
      }
    }
  }
}

override template errorTemplateAction( messages: [String] ){
  for( ve in messages ){
    div[ class="row justify-content-md-center" ]{
      div[ class= "col-sm-2" ]
      div[ class= "col-sm-2" ]{
        span[ style := "color: #FF0000" ]{
          text(ve)
        }
      }
    }
  }
  elements
}

override template templateSuccess( messages: [String] ){
  for( ve in messages ){
    span[ style := "color: #BB8800;" ]{
      text(ve)
    }
  }
}


section session entity

session basket {
  wants : {Item}
}

page testSession{
  main {
    for( i: Item ){
      if( i in basket.wants ){
        submitlink action{ basket.wants.remove( i ); }{ "remove ~i.name" }
      } else {
        submitlink action{ basket.wants.add( i ); }{ "add ~i.name" }
      }
    }
    "currently in basket: "
    for( i in basket.wants ){
      output( i.name )
    } separated-by { ", " }
  }
}


section expressions

function globalfunc( s: String ): Int {
  return s.length();
}

extend entity Item {
  function repeatName() {
    name := name + name;
  }
}

page testExpressions {
  init {
    var i := 1;
    var s := "" + i;
    var w : WikiText := s;
    log( "i:~i s:~s w:~w" );
    var list : [Item]; // empty list, {Item} for Set
    var item : Item; // null
    item := Item{ name := "test" };
    list.add( item );
    log( "list length: ~list.length" );
    list.remove( item );
    log( "list length: ~list.length" );
    var listcreation := [ Item{ name := "i1" }, Item{ name := "i2" } ];
    // list comprehension, creates new List instance
    log( [ it.name | it in listcreation ] );
    var otherlist := [ x | x in listcreation where x.name != "" order by x.name desc ];
    var itemnames := [ x.name | x in (from Item) where x.name == "apple" ];
    log( itemnames );
    // functions
    otherlist[ 0 ].repeatName();
    log( "name length: " + globalfunc( otherlist[ 0 ].name ) );
    // embedded queries
    var itemshql := from Item as i where i.name <> '' order by i.name limit 1;  // returns [Item]
    log( "itemshql: " + itemshql[ 0 ].name );
  }
  main {
    testExpressionsTemplate
  }
}

template testExpressionsTemplate {
  for( i: Item ){
    for( j: Item ){
      if( i != j ){
        div { output( i.name ) "-" output( j.name ) }
      }
    }
  }
  var list := [ x.name | x in (from Item) where x.name == "apple" ]
  for( n in list ){
    div { "item from list: ~n" }
  }
  for( i in [1,2,3,4,5] where i > 3 order by i desc ){
    div { "number: ~i" }
  }
  submit action {
    var t := TestExpr{ s := "newitem" };
    t.s := "~t.s  ~t.l()";
    t.save();
  }{ "run" }
  for( t: TestExpr ){
    div{ output( t.s ) }
  }
}

entity TestExpr {
  s : String
  function l: Int { return s.length(); }
}


section form inputs

entity Item {
  name : String
}

init {
  Item{ name := "apple" }.save();
  Item{ name := "orange" }.save();
  Item{ name := "pear" }.save();
}

entity Collection {
  i : Int
  b : Bool
  f : Float
  s : String
  e : Email
  se : Secret
  w : WikiText
  t : Text
  ref : Item
  set : {Item}
  list : [Item]
  derived : Int := list.length
  date : Date
  dateTime : DateTime
}

var testcollection := Collection{}

page types {
  var c := testcollection
  <style>
    label, button {
      display: block;
    }
  </style>
  form {
    label( "Int" ){      input( c.i ) }
    label( "Bool" ){     input( c.b ) }
    label( "Float" ){    input( c.f ) }
    label( "String" ){   input( c.s ) }
    label( "Email" ){    input( c.e ) }
    label( "Secret" ){   input( c.se ) }
    label( "WikiText" ){ input( c.w ) }
    label( "Text" ){     input( c.t ) }
    label( "EntRef" ){   input( c.ref ) }
    label( "Set" ){      input( c.set ) }
    label( "List" ){     input( c.list ) }
    label( "Derived" ){  output( c.derived ) }
    label( "Date" ){     input( c.date ) }
    label( "DateTime" ){ input( c.dateTime ) }
    submit action{} { "save" }
  }
  navigate root(){ "root" }
}


section bootstrap and template element abstraction

template bootstrap {
  // https://getbootstrap.com/docs/5.0/getting-started/introduction/#starter-template
  head {
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BmbxuPwQa2lc/FVzBcNJ7UAyJxM6wuqIj61tLrc4wSX0szH/Ev+nYRRuWlolflfl" crossorigin="anonymous">

    <title>"demo"</title>
  }
}

template bootstrapJavaScript {
  <!-- Option 1: Bootstrap Bundle with Popper -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/js/bootstrap.bundle.min.js" integrity="sha384-b5kHyXgcpbZJO/tY9Ul7kGkf1S0CWuKcCD38l8YkeH8z8QjE0GmW1gYU5S9FOnJ0" crossorigin="anonymous"></script>
}

template main {
  bootstrap
  elements
  navigate root(){ "root" }
  bootstrapJavaScript
}

page typesWithStyling {
  var c := testcollection
  main {
    form {
      // https://getbootstrap.com/docs/5.0/forms/form-control/
      <div class="row justify-content-md-center">
        label( "Int" )[ class= "col-sm-2 col-form-label" ]{
          div[ class= "col-sm-2" ]{
            input( c.i )[ class= "form-control" ]
          }
        }
      </div>
      mylabel( "String" ){ input( c.s ) }
      mylabel( "Bool" ){   input( c.b ) }
      mylabel( "Float" ){  input( c.f ) }
      mylabel( "Ref" ){    input( c.ref ) }
      input( "Set", c.set )
      input( "List", c.list )
      mylabel( "Derived" ){ output( c.derived ) }
      <div class="row justify-content-md-center">
        submit action{}[ class= "btn btn-primary col-sm-4" ] { "save" }
      </div>
    }
  }
}

template mylabel( label: String ){
  <div class="row justify-content-md-center">
    label( label )[ class= "col-sm-2 col-form-label" ]{
    <div class="col-sm-2">
      elements
    </div>
    }
  </div>
}

override attributes submit{ class="btn btn-default" }
attributes btnSuccess { class= "btn btn-success" }
attributes btnWarn{ class= "btn btn-warning" }
attributes btnDanger{ class= "btn btn-danger" }
attributes btnPrimary { class= "btn btn-primary" }
override attributes submitlink{ btnPrimary attributes submit attributes }

override attributes inputInt{ class="inputInt form-control" }
override attributes inputString{ class="inputString form-control" }
override attributes inputEmail{ class="inputEmail form-control" }
override attributes inputSecret{ class="inputSecret form-control" }
override attributes inputURL{ class="inputURL form-control " }
override attributes inputText{ class="inputTextarea inputText form-control" }
override attributes inputWikiText{ class="inputTextarea inputWikiText form-control" }
override attributes inputFloat{ class="inputFloat form-control" }
override attributes inputLong{ class="inputLong form-control" }
override attributes inputDate{ class="inputDate form-control" }
override attributes inputSelect{ class="select form-control" }
override attributes inputSelectMultiple{ class="select form-control" }
override attributes inputFile{ class="inputFile  form-control" }
override attributes inputMultiFile{ class="inputFile  form-control" }
override attributes inputSDF{ class="inputSDF form-control" }

expand
  Item
  Float
  Int
  String
  to customInput

expandtemplate customInput to Type {
  template input( label: String, t: ref Type ){
    mylabel( label ){ input( t ){ elements } }
  }
}

expand
  Item
  to customInputCollections

expandtemplate customInputCollections to Type {
  template input( label: String, t: ref {Type} ){
    mylabel( label ){ input( t ){ elements } }
  }
  template input( label: String, t: ref [Type] ){
    mylabel( label ){ input( t ){ elements } }
  }
}
