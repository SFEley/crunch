Crunch
======
Crunch is an alternative MongoDB driver with an emphasis on high concurrency, atomic update operations, and document integrity. It uses EventMachine for non-blocking writes and reads, with optional synchronous wrappers for easy integration with non-evented applications. Its API is simpler and more Rubyish than the official MongoDB Ruby driver, but aims to support the same range of MongoDB features.

_(**DISCLAIMER:** It isn't fully baked yet.  This README was written early in the process to document the design principles.  Much of what you'll read below doesn't work yet, and any of this is subject to change as ideas are proven unsound through experimentation.  Please don't try to use this in any serious code until it's ready.  You'll know when it's ready because this text won't be here.)_

Structure
---------
Although it wraps the Mongo wire protocol, Crunch diverges conceptually from the "flat struct" operations that the protocol encourages.  It's always bugged me a bit that Mongo interfaces overload the collection class with document-specific operations, while documents themselves are unclassed hashes with vague limitations.  Meanwhile, the division of responsibility between connections, databases, and collections is murky and often overlapping.  This isn't a flaw in Mongo's architecture, nor is it bad coding on the part of the driver developers.  It comes from trying to impose a _thin_ object-oriented layer on top of a purely functional binary protocol.  

Crunch offers a different perspective on the same actions. At the highest level, there are three major classes to understand: the **Database**, the **Query** (of which **Collection** is a subclass), and the **Fieldset** (of which **Document** is a subclass). All database structures are _immutable_ -- once created, they can't be changed. An intermediate level manages connections and BSON serialized messages conforming to Mongo's wire protocol, and EventMachine takes care of sending and receiving binary data from the server.

![Class diagram](https://sfe_misc.s3.amazonaws.com/crunch_class_diagram.svg)

Synchronous vs. Asynchronous
----------------------------
Crunch's relationship with EventMachine can be summarized as follows:

1. Communicate with the MongoDB server entirely using asynchronous calls and callbacks.
2. By default, sleep until the answers come back so that the user doesn't have to understand step 1.
3. Provide options and bang-methods (e.g., `.update!` instead of `.update`) so that users who _know_ what they're doing aren't bogged down by step 2.

That's the Crunch pattern in a nutshell. More primer material follows; if you understand asynchronous programming already, you can skip the next subsection.

### A Bit of Background ###

Event-driven programming is a _huge_ benefit when it comes to handling a very heavy volume of updates and queries. By using EventMachine's reactor loop, Crunch's performance on concurrent operations (a lot of threads, a lot of fibers, etc.) comes much closer to being limited only by the DB's server speed or network bandwidth.  But it does make things more complicated, and it encourages a style of programming that's only partly intuitive to most Ruby developers. 

We're all familiar with code blocks, and many of us understand why they're one of the most powerful parts of Ruby.  But most of us still use a **synchronous** model for our business logic.  If you have one method (say, a Rails controller action) that does something like: _"Get some input, then make a new record, then save the record, then check for errors, then tell the user about it"_  -- that's a synchronous method. 

An **asynchronous** model may have the same actions in the same order, but the method is exploded into several fragments.  There isn't one single block of code that contains all of those operations.  Instead, the _"Get some input"_ step may be a block that's invoked when data's received on the network connection.  That block may tell the database to _"Make a new record"_ and pass it both the input and another block.  The _"Get input"_ block ends there, and the database driver does its thing in the background. When it's done, that second _"New record"_ block is run, telling the database to _"Save the record"_, and hands over _yet another_ block to say what should happen after the record is saved. It might even pass two: one for success and one for failure.  Both would presumably return different things to the user, or otherwise do whatever logically comes next.

All of these blocks are **callbacks.**  Javascript developers are probably snoring by now, because this is how most things happen in the browser. Asynchronous programming tends to happen in chains of callbacks -- sometimes long or convoluted chains with lots of branches.  It's not for the faint of heart. The _benefit,_ however, is that your code is never stuck twiddling its thumbs waiting for some external dependency to come back.  Instead you have small discrete chunks of _before_ and _after_ code, and the time in between can be spent doing...anything.  Say, handling small chunks of code for the other 9,999 requests that came in the last two seconds.  That's what makes it fast.

### Crunch and the Loop ###

Crunch requires an EventMachine reactor loop to be running.  If you are already writing an EM-driven application, or using Thin or another evented application server, great. EventMachine will already be running and Crunch will simply insert its own actions into the loop.  If your architecture is asynchronous, you may wish to set the global option `Crunch.synchronous = false` so that you don't have to worry about when to use bang methods. (See the following sections.)

Otherwise, if EM _isn't_ running, the first call to `Database.connect` will start the EM reactor in a separate thread.  Any Crunch methods that talk to a MongoDB server (and a few that don't) will run in that thread and set thread-safe attributes to indicate completion or state of readiness.  Most of the _synchronous_ methods in Crunch simply call the asynchronous forms, then use monitors to sleep until the object's state says it's done.

It sounds complicated, but from the end user side we've tried to keep it simple.  This is the sanest way to build a library that has asynchronous components without forcing you to twist your entire application around the library.  (As an aside, it's also why we didn't use Ruby 1.9 fibers instead of threads.  It's just no good for an EM-agnostic library: to make it work properly, _your_ code would have to know when to yield or resume to the EM reactor's fiber, and then it starts to get ugly.)


Database
--------
The **Crunch::Database** class abstracts all communication with the server. There is one singleton Database object per Mongo database, and each maintains one or more server connections. Because it's a singleton, you invoke the instance with `.connect` rather than `.new`:

    db = Crunch::Database.connect 'my_database', host: 'example.org', port: '71072'
    
(The _host_ and _port_ default to localhost and 27017, of course.)

Groups and Documents make queries or updates by passing messages to their Database.  The Database then forwards the message to a subclass of EventMachine::Connection, which sends the binary data to the MongoDB server.  In the case of queries, a reference to the originating Group or Document is also passed so that it can be told to update itself when the response comes back.

Query
-----
The **Crunch::Query** class retrieves data from the database and presents it as an Array-like Enumerable. Unlike many other database libraries, basic Crunch queries are _immediate_ and _immutable_.  They'll ask the server for a cursor the moment they're instantiated (unless you flag them not to) and any changes made to retrieved data won't be reflected until you make another query. The server request is always asynchronous. Synchronous delays will only occur if you try to _read_ the data before it returns -- and you can still avoid them by passing a block.

This behavior enables speed (the data's on its way before you start to look at it) and simplicity (the cursor itself is an internal detail hidden from the API). MongoDB never guarantees transactional isolation, but Crunch timestamps every server response, so you can know how stale your data might be and whether a refresh is needed. You never reload data in place; you simply clone the query and get the data again. Several other base classes use Queries under the hood.

### Creation ###
You can create a Query in several ways, depending on how much work you already want done for you. The options hashes in the examples below may not make sense immediately; it'll be covered shortly.

#### Directly ####
Pass the database and collection (as a string or Collection object) in the first two parameters.  So:

    db = Database.connect 'babylon_5'
    collection = db.collection :characters
    query = Query.new db, collection, 'species' => 'Vorlon', :limit => 1

...is precisely equivalent to:

    db = Database.connect 'babylon_5'
    query = Query.new db, 'characters', conditions: {species: 'Vorlon'}, limit: 1
    
#### From the Database ####
Use the `query` method of the Database object, passing the collection (as a string or Collection object) in the first parameter:

    query = db.query 'characters', 'role' => 'Commander', 'last_name' => /S[hi].*/, 'messianic' => true
    query.collect {|c| c['last_name']}   #=> ['Sinclair', 'Sheridan']
    
#### From a Collection ####
Use the `query` method. This time you only have to worry about your options hash:
    
    collection = DB.collection 'characters'
    query = collection.query 'species' => 'human', 'psi_rating' => {gte: 12}, 'personality' => {in: 'annoying'}
    query.count  #=> 3  (by my reckoning)

#### From Another Query ####
Queries can spawn other queries. The new query inherits all the options of its parent, but these can be added to or overridden:

    first_query = collection.query 'bald' => false, :fields => ['species']  # (Which species have hair?)
    first_query.collect {|c| c['species']}  #=> ['Human', 'Centauri'] 
    second_query = first_query.query 'sex' => 'female'  # (Centauri women are bald)
    second_query.collect {|c| c['species']}  #=> ['Human']  (includes post-season-2 Delenn as a technicality)
    
### Retrieval ###
The Query object is a self-contained capsule of data -- it contains both the question (via its initialization parameters) and the answers (via accessors).  For example:

    query = Query.new db, 'musicians', 'band' => 'The Beatles'
    query.first  #=> {'_id' => [...], 'name' => 'John Lennon', ...}
    query.next   #=> {'_id' => [...], 'name' => 'Paul McCartney', ...}
    query[2]     #=> [{'_id' => [...], 'name' => 'Ringo Starr', ...}]
    query.any? {|beatle| beatle['name'] == 'Yoko Ono'}  #=> false

Each item returned is a Document object (see below).  The interesting Query methods to get to them are summarized below; most of the other access behavior comes from the standard Enumerable mixin: 

* `[]` - Returns the Document at the given index. If the data retrieval hasn't gotten that far yet, the method will block until it does. (_Note:_ Don't make the mistake of confusing Queries for Arrays just because of this bracket thingy. This is the _only_ array-like method.)
* `at` - A non-blocking accessor. Accepts an index like `[]` and a block of code, and will pass the document to the block upon retrieval. The return value is a proc that will return _false_ when called if the code has not yet been executed, _true_ if it has been, and raise any exceptions that arise during execution.
* `first` - Returns the first document of the result set. If the data retrieval hasn't pulled the first record yet, the method will block until it does. (Call `ready?` beforehand to avoid this blocking.)
* `last` - Returns the last document in the result set.  This requires traversing the entire cursor, so if the data retrieval is not yet complete, the method will block until all records have been loaded.
* `each` - Steps through the entire result set and passes each document to the provided block of code.  This method is synchronous and will block until the entire run is completed. Returns an Enumerator if no block is given, so that you can call `next` and friends at your leisure.
* `each!` - An asynchronous form of `each` that runs the provided block on each document in the EventMachine thread. Returns a proc that wil return _false_ if the iteration is not yet complete, _true_ if it is complete, and raise any exceptions that arise during execution.
* `size` - Returns the _current_ number of documents that have been loaded. See _Size vs. Count_ below.
* `count` - Returns the number of documents in the query as reported by MongoDB. Will likely block for a time unless the **:count** option is set upon initialization. See _Size vs. Count_ below.
* `ready?` - A thread-safe flag that returns _true_ if the first document in the result set has been loaded.
* `complete?` - A thread-safe flag that returns _true_ if every record in the result set has been loaded.
* `has?` - Takes an index and returns _true_ if the record at that position in the result set has been loaded.

All of these methods are thread-safe and as consistent as MongoDB will allow them to be. The actual cursor is a hidden property owned by the database object, so that it can be explicitly closed if the query is garbage collected before completion.

#### Lookahead and Retain ####

The two hazards of traversing a large query in MongoDB are memory usage and speed.  If space and time weren't issues, we'd load every record into an array immediately for full random access.  In the real world this is often practical for smallish result sets, but a Ruby array of millions or billions of documents would bring your application to its knees.  It's also not always necessary.  Some use cases require random access, but sometimes you just want to step through each record once and be done with it.

Crunch provides two facilities to balance these constraints.  The first is the _lookahead_ system.  Mongo cursors deliver documents in batches.  (The default is 100, but this can be configured with the **:batch** option.)  Crunch tries to stay a little ahead of your document access by making `GET_MORE` calls to the server for the next batch before it's needed.  By default it runs one batch ahead, so the flow of data runs something like this:

1. The Query fires a message off to the server as soon as it's created. We're using EventMachine, so nothing else happens until the server responds.
2. The server's reply contains a cursor ID and the first 100 documents.  The Query parses these records in the background and stores them in an internal array, where they wait for your application to read them. 
3. As soon as document #1 is accessed -- or any of them -- the Query requests the next batch (documents 101 to 200). When the batch is received, they are silently added to the array. Ideally this process will be complete before you need them.
4. When document #101 or later is accessed, the Query requests the _next_ batch.
5. Rinse, repeat.

If running a hundred documents ahead isn't enough (perhaps because your code's too fast) you can set a higher integer value for the **:lookahead** option on query creation.  A value of 2 would try to stay _two_ batches ahead of your data access, et cetera.  

The option also accepts two special non-integer values.  The _:none_ value


Once created, the Query will immediately get to work by firing off a message to the MongoDB server.  The query and response are handled by EventMachine in the background; your application can go about its business, performing other tasks, and look at the query's data at its leisure.  You will experience synchronous delays in your application thread _if and only if_ you try to view a document that has not yet been retrieved or call the `.count` method.  You can avoid these delays by passing a callback or by checking the `.ready?` method.



### Options ###
Because Queries are immutable, all options must be passed at initialization.  Only the **database** and **collection** parameters are required; a query without any other options simply returns all documents in the collection. 

The options hash may contain both search conditions and defined options, mingled interchangeably.  Any keys that the Query class doesn't know about are passed to MongoDB as search conditions.  Options are always symbols.  To avoid confusion and name collisions, we _strongly_ suggest using strings for search keys, or else use the explicit **:conditions** option:  

    highways = db.collection 'roads'
    highways.query 'limit' => 70, :limit => 5           # Returns the first 5 roads with a speed limit of 70
    highways.query conditions: {limit: 70}, limit: 5    # The same (using Ruby 1.9 hash syntax)
    
#### MongoDB Options ####
The following options are defined by the MongoDB server and passed along in the query message:

* **:conditions** _(Hash)_ Explicit search conditions. See above.
* **:fields** _(Array)_ Only return these document fields.  (*'_id'* is always included.)
* **:limit** _(Integer)_ Return at most _N_ matching documents.
* **:skip** _(Integer)_ Start at the _N+1_th matching document.
* **:sort** _(String, Array or Hash)_ See below.

Sorting is as simple or complex as you want it to be.  A single string means to sort on that key in ascending (default or "natural") order.  An array can be used to specify several sort keys in order.  Each element can be a simple string (again implying ascending order) or a two-element array of the key name and direction:

    sort: ['last_name', ['age', -1], ['height', :up]]   # You can use :up and :down in place of 1 and -1

For a complex sort order like this, it's cleaner to use a hash. Hashes in Ruby 1.9 are ordered, so the sort priority is retained:

    sort: {'last_name' => :up, 'age' => :down, 'height' => :up}

#### Retrieval Options ####
The following options are defined by Crunch and influence when and how the query pulls data.  See the 'Retrieval' section below or the documentation for more details.

* **:run** _(Boolean)_ If false, do _not_ execute the query until the `run` method is called or data is read. Useful if you're setting up a base query for later execution or modification.
* **:batch** _(Integer)_ Return _N_ documents from the cursor per request. Defaults to 100. 
* **:lookahead** _(Integer, :none, or :all)_ Load data _N_ requests ahead of data access. Defaults to 1.
* **:retain** _(:none, :all, or :weak)_ Whether to keep document references after access. Defaults to _:all_.
* **:count** _(Boolean)_ Request the document count for this query. Saves time if the `.count` method is called later. Defaults to false.

#### Blocks and Block Options ####
Hard-core asynchronists can skip in-line interaction with the Query entirely and specify callbacks to operate when the application isn't looking.  If a block is passed to `Query.new` or any of the various `.query` methods, it is automatically called by EventMachine on each document in the result set in turn:

    cartoon_characters.query 'type' => 'Care Bear' do |bear|
        puts bear['name'] + ': ' + bear['cheesy_symbol']
    end

Passing a block implicitly sets **:forward** to true for memory conservation, but you can override this if you want to hold onto the data for your own purposes.

For more refinement, you can pass procs or lambdas to the following query options:

* **:each** _(Proc)_ Same as the method block parameter above.  Useful for clarity if you're going to pass more than one proc. Takes a document from the result set as a parameter.
* **:on\_ready** _(Proc)_ Called once the first document is loaded into memory. Takes the query as a parameter. Useful if you want to avoid synchronous delays while waiting for the server to process.
* **:on\_retrieval** _(Proc)_ Called after each cursor return.  Takes a counter and the retrieved batch (subset of documents) as parameters. Useful if you want to display progress or avoid synchronous delays from the network.
* **:on\_completion** _(Proc)_ Called once the last document is loaded into memory. Implicitly sets **:lookahead** to _:greedy_ and **:forward** to false unless overridden. Takes the query as a parameter. Useful if you want to do something to the entire enumerable _other than_ stepping through it. (Don't use for huge result sets!)
* **:on\_error** _(Proc)_ Called on query failure. Takes the query and an exception object as parameters.






    
    

    




Document
--------
The **Crunch::Document** class allows MongoDB documents to create, read, update, or delete themselves on an individual basis.  It's duck-typed to a Hash, except that all keys are converted to strings on assignment and any values which cannot be serialized to BSON will raise an exception.

### Creation ###

You can create an unsaved Document from scratch by passing it a Database and a collection name or Collection object:

    my_document = Document.new db, 'my_collection'

You can also pass a hash of initial data. The new Document will have a generated ObjectId unless you pass it an `:id` parameter. Call `.insert` or `.save` at any time to bring it into the database.

You can insert documents as a hash into a Database or Collection object with the `.insert` method: 

    db.insert 'my_collection', 'foo' => :bar, 'abc' => [1, 2, 3]
    my_collection.insert 'foo' => :bar, 'abc' => [1, 2, 3]
    
Both will immediately return a Crunch::Document object that can be used for subsequent updates.  Inserts are synchronous by default, in that **getLastError** is immediately called to confirm the operation and the method sleeps until it returns. If you wish to make an asynchronous update, use the bang form: `my_collection.insert! 'foo' => :bar`. (This is reasonably safe and recommended in most circumstances, even if you prefer synchronous reads.)


### Retrieval ###

Documents can be retrieved from Databases, Collections or Groups with the `.document` method. You can pass the document's ID or a hash of query options:

    id = Crunch.oid '4c14f7943f165103d2000015'  # Makes a BSON ObjectId from a string or number
    db.document 'my_collection', id
    my_collection.document id
    my_collection.document name: /Joe/, age: {'$lt' => 35}  # Returns the first document matching the query parameters
    my_group.document age: 35  # Inherits the query parameters of the Group
    my_group.document name: /Joe/, fields: [:name, :age]  # Limits fields returned
    
Queries are sent to the MongoDB server as-is, with only basic BSON serialization performed.  You can include any of the advanced query operators, e.g. **$gte**, **$in**, **$not**, etc.

#### Asynchronous Retrieval ####

Single-document retrievals are synchronous by default: the `.document` method won't return until the data has been returned from MongoDB and deserialized.  Failures will return an exception from the method. You can make the retrieval asynchronous in a few ways:

1. You can call the bang form of the method: `my_collection.document! id`. You can optionally pass a block as well. The Document object will return immediately, and the block (if given) will be attached as a success callback. You can check the `.ready?` attribute at any time to determine whether the data is available yet.  Attempts to read the data before it's ready will throw an exception.
2. You can globally set `Crunch.synchronous = false` on application initialization.  Document retrieval will then act like its bang form described above.
3. You can pass the `:synchronous => false` option to the `.document` method.  It will then act like its bang form.

The Document method that's returned includes the **EventMachine::Deferrable** module, and therefore can have callbacks attached to it at any time.  

#### Reloading Documents ####

In a highly concurrent Mongo environment, there is no assurance that a Document won't go stale while you're working with it.  You can retrieve the data from MongoDB again at any time by using the `.refresh` (synchronous) or `.refresh!` (asynchronous) methods. On completion, the refresh will overwrite the data in the Document on which the method is called. However, you can pass a `:clone => true` option to either method; this will return a _new_ Document object pointing to the same document in MongoDB, leaving the current Document's data unchanged. 

The `.refresh!` method can also take a `:periodic` option (e.g. `my_document.refresh! :periodic => 0.1`) which sets a timer to refresh the data every _n_ seconds until the document is garbage collected. Only one timer is set per Document, so you can alter the interval with subsequent calls or cancel it by passing `:periodic => (nil or false)`.
Finally, you can pass it a block to be executed after the data is ready.

**IMPORTANT:** Crunch is thread-safe in the sense that fieldsets are immutable and access to them in document objects is controlled by writer-reader locks. However, for _your application logic_, trying to do computation with data that's constantly changing in the background can be fraught with peril. If you're going to turn on periodic refreshes, make sure you know what you're doing. (You could also use the :periodic and the :clone options together, but then you have a different problem in figuring out what to do with all those copies. Watch Disney's _Sorceror's Apprentice_ again before you do this.)

### Updates ###

Once retrieved, the Document can be treated like a hash with indifferent access:

    my_document['age'].equal? my_document[:age]   # true
    my_document['name'] = "Jill"  # Does not immediately save to MongoDB
    my_document.keys  # ['age', 'name', _et cetera_]

Call `.save` to update MongoDB with the changed document. This will overwrite the document in the database, losing any other changes that may have been made between retrieval and save.  The `.save` method is synchronous by default, but can be called with the `.save!` bang form for asynchronous saves.

#### Atomic Updates ####

Crunch offers simple support for Mongo's atomic update operators -- in fact it's the preferred approach for changing documents.  The Document object has methods for every atomic operator:

    my_document.set name: 'Jill', age: 27
    my_document.inc :age, weight: 2  # Non-hash parameters will default to an increment of 1
    my_document.unset :name, :age
    my_document.push pets: 'dog' 
    my_document.push_all pets: ['dog', 'cat', 'iguana'] 
    my_document.pull pets: 'dog'
    my_document.pull_all pets: ['dog', 'cat', 'iguana']
    my_document.pop friends, pets: -1  # Non-hash parameters will default to 1
    my_document.add_to_set pets: 'dog'
    
(Note the mixing of hashed and non-hashed parameters.  Per Ruby syntax rules, hashed parameters must come at the end or be wrapped in _{curly braces}_.)

By default, atomic updates don't happen immediately; they're saved in a special hash in the Document and executed all at once when the `.update` method is run:

    my_document.set name: 'Jill', hair: :red
    my_document.inc 'age'
    my_document.set height: 64.0
    my_document.update  # Executes changes to name, hair, age and height

As with `.insert` and `.save`, the default form of `.update` is synchronous and calls **getLastError** to confirm the update before returning. You can make it asynchronous with the bang form, and optionally provide a block as a callback: 

    my_document.set name: 'Jill', hair: :red
    my_document.inc 'age'
    my_document.update! {|doc| doc.refresh!}  # There's a better way -- see the next section
    
For one-line updates, you can also pass operations to the `.update` and `.update!` methods -- or simply use the bang forms of the atomic operators:

    my_document.update set: {name: 'Jill'}, inc: {'age'}  # Equivalent to three lines of code
    my_document.update! inc: :age 
    my_document.inc! :age  # Equivalent to the line above
    my_document.push_all! pets: ['dog', 'iguana'] {|doc| doc.notify_iguana_owners}  # Yes, you can add a block as a callback
    
#### Atomic Find-and-Modify ####

It's a very common task to make a change, then reload the document to see what changed -- particularly with indeterminate operators such as **$inc** or the array modifiers. MongoDB supports update-and-retrieval as an atomic operation with the **findAndModify** command. You can use this for your own updates by calling the `.modify` method rather than the `.update` method:

    my_document.set name: 'Jill', hair: :red
    my_document.inc 'age'
    my_document.modify push: {pets: 'dog'}  # Updates name, hair, age and pets, then changes the Document
    
By default, the `.modify` method returns the Document as it exists _after_ the change has been made.  (I.e., it sets the **findAndModify** command's _new_ flag to true.)  If you'd rather retrieve the document from _before_ the change, pass the `:new => false` option.  This is most useful with the **$pop** and **$pull** operators, to see precisely what was removed.  You can also pass the `:clone => true` option, which returns a new Document object with the changes instead of altering the Ruby object on which the operation was performed.

The synchronous form of `.modify` blocks until the result document is returned and has been refreshed into the Document (or the Document's clone). By now you've probably guessed that you can make it asynchronous and optionally pass a block to it with `.modify!` Note that the prior caution about asynchronous changes to data that you're in the middle of using still applies.


Query
-----
A **Crunch::Query** object represents a retrievable set of Documents -- i.e., the result set of any query that isn't known to refer to just one record.  The object is initialized with its Database, a collection name, and an immutable set of query criteria and fields.  The query itself is run on an "as needed" basis, with cursors and _"GETMORE"_ operations managed asynchronously in the background.  Queries can be instantiated from a Collection or from another Query (in which case they inherit any existing parameters):

    # Create a Query from a Collection object (this is equivalent to the above)
    my_query = my_collection.query conditions: {name: /Joe/}, fields: [:name, :birthdate]
    
    # Create a Group from a Group object (this one will already be constrained by the above query)
    subquery = my_query.query conditions: {weight: {'$lte' => 225}}, sort: :birthdate, limit: 20
    

Queries are partially duck-typed to arrays, and can be accessed by index or enumerated using any of the standard Enumerable methods:

    group.first       # Returns the first Document that meets query conditions
    group[17]         # Returns the 17th Document that meets query conditions
    group[101..200]   # Returns the second hundred Documents
    group.each {|doc| do_something}  # Runs the block on every Document
    
### Asynchronous Operations ###

Direct updates and deletes are always asynchronous, returning immediately with a reference to the Group (thus allowing chaining).  Chains of method calls are guaranteed to be done in order, but _when_ they occur is up to EventMachine.

By default, the `.each` method and most other Query methods that retrieve data are synchronous: they'll block the current thread until the full operation completes.  To be precise, they won't come back until the `.deferred_status` of every Document involved is _:succeeded._  (And they'll throw an exception if it comes back _:failed._) This is a developer convenience in recognition of the fact that _most_ Ruby applications aren't built with an event-driven "inversion of control" mindset. And that's fine.  For many jobs, wrapping everything into a chain of callbacks would only increase complexity with little or no practical benefit.

However, for cases when it makes sense, there are several ways to perform asynchronous reads:

2. Methods that default to synchronous can be called with the bang modifier, e.g. `.each!` or `.first!` or `.select!` and so forth. This will return a Deferrable object that you can monitor or ignore as you see fit. When the `.deferred_status` is _:succeeded_, the retrieval is done. Any blocks passed will be run as callbacks after the data is there.
2. The `[]` accessor method can also be passed a block, e.g.: `my_query[21] {|doc| do_something}`. This will act like the bang form described above, with the block attached as a callback to a deferrable Document or array of Documents.
1. You can globally set `Crunch.synchronous = false` on application initialization, before the Database is instantiated. All synchronous methods will then act like their bang forms described above.
2. You can initialize the Database or Query with the `:synchronous => false` option. All synchronous methods will then act like their bang forms described above.
3. You can _temporarily_ set specific operations as asynchronous by passing them as a block to the `.asynchronous` method: `my_group.asynchronous do ... end`.

Likewise, if global options are set to be asynchronous, you can still make some actions synchronous with the `:synchronous => true` initialization option or by wrapping them in `.synchronous` blocks.

 










