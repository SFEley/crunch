Crunch
======
Crunch is an alternative MongoDB driver with an emphasis on high concurrency, atomic update operations, and document integrity. It uses EventMachine for non-blocking writes and reads, with synchronous fallback for easy integration with non-evented applications. Its API is simpler and more Rubyish than the official MongoDB Ruby driver, but aims to support the same range of MongoDB features.

_(**DISCLAIMER:** It isn't fully baked yet.  This README was written early in the process to document the design principles.  Much of what you'll read below doesn't work yet, and any of this is subject to change as ideas are proven unsound through experimentation.  Please don't try to use this in any serious code until it's ready.  You'll know when it's ready because this text won't be here.)_

Structure
---------
Although it wraps the Mongo wire protocol, Crunch diverges conceptually from the "flat struct" operations that the protocol encourages.  It's always bugged me that Mongo interfaces overload the collection class with document-specific operations, while documents themselves are simple hashes with vague limitations.  Meanwhile, the division of responsibility between connections, databases, and collections is murky and often overlapping.  This isn't a flaw in Mongo's architecture, nor is it bad coding on the part of the driver developers.  It comes from trying to impose a _thin_ object-oriented layer on top of a purely functional binary protocol.  

Crunch presents a more object-driven layer over the same operations. At the highest level, there are four major classes to understand: the **Database**, the **Collection**, the **Query**, and the **Document**.  The **Fieldset** utility class (of which **Document** is a subclass) is used in place of hashes.  Any Crunch objects representing data are _immutable_ -- once created, they can't be changed. An intermediate level manages connections and BSON serialized messages conforming to Mongo's wire protocol, and EventMachine takes care of sending and receiving binary data from the server.

Synchronous vs. Asynchronous
----------------------------
Crunch's relationship with EventMachine can be summarized as follows:

1. Communicate with the MongoDB server entirely using asynchronous calls and callbacks.
2. Pre-load a reasonable amount of data in the event loop before the application asks for it.
3. Allow the application to provide blocks (callbacks) to operate on data as it comes in.
4. If the application does _not_ provide callbacks, and asks for data we don't have yet, get the data and make it wait.  We call this _synchronous fallback_, but in practice it's probably more common.

That's the Crunch pattern in a nutshell. More primer material follows; if you understand asynchronous programming already, you can skip the next subsection.

### A Bit of Background ###

Event-driven programming is a _huge_ benefit when it comes to handling a very heavy volume of updates and queries. By using EventMachine's reactor loop, Crunch's performance on concurrent operations (a lot of threads, a lot of fibers, etc.) comes much closer to being limited only by the DB's server speed or network bandwidth.  But it does make things more complicated, and it encourages a style of programming that's only partly intuitive to most Ruby developers. 

We're all familiar with code blocks, and many of us understand why they're one of the most powerful parts of Ruby.  But most of us still use a **synchronous** model for our business logic.  If you have one method (say, a Rails controller action) that does something like: _"Get some input, then make a new record, then save the record, then check for errors, then tell the user about it"_  -- that's a synchronous method. 

An **asynchronous** model may have the same actions in the same order, but the method is exploded into several fragments.  There isn't one single block of code that contains all of those operations.  Instead, the _"Get some input"_ step may be a block that's invoked when data's received on the network connection.  That block may tell the database to _"Make a new record"_ and pass it both the input and another block.  The _"Get input"_ block ends there, and the database driver does its thing in the background. When it's done, that second _"New record"_ block is run, telling the database to _"Save the record"_, and hands over _yet another_ block to say what should happen after the record is saved. It might even pass two: one for success and one for failure.  Both would presumably return different things to the user, or otherwise do whatever logically comes next.

All of these blocks are **callbacks.**  Javascript developers are probably snoring by now, because this is how most things happen in the browser. Asynchronous programming tends to happen in chains of callbacks -- sometimes long or convoluted chains with lots of branches.  It's not for the faint of heart. The _benefit,_ however, is that your code is never stuck twiddling its thumbs waiting for some external dependency to come back.  Instead you have small discrete chunks of _before_ and _after_ code, and the time in between can be spent doing...anything.  Say, handling small chunks of code for the other 9,999 requests that came in the last two seconds.  That's what makes it fast.

### Crunch and the Loop ###

Crunch requires an EventMachine reactor loop to be running.  If you are already writing an EM-driven application, or using Thin or another evented application server, great. Crunch will notice that EventMachine is already running and simply insert its own actions into the loop.  If EM _isn't_ running, the first call to `Database.connect` will start the EM reactor in a separate thread.

The public interface of Crunch does _not_ take place in the EventMachine loop.  It runs in your own application's thread(s).  If you ask for a Mongo operation that does not require a response (i.e. an insert, update, or delete) it'll inject the proper code into the EM loop and return right away.  If you make a request that needs an answer (i.e. queries, or updates in 'safe mode') then the Crunch method you called will not return until the answer comes back.  You can bypass this behavior and make it return immediately by giving it a block to run on the response.

It sounds complicated, but from the end user side we've tried to keep it simple.  It's the sane way to build a library that has asynchronous components without forcing you to twist your entire application around the library.  (As an aside, it's also why we didn't use Ruby 1.9 fibers instead of threads.  It's just no good for an EM-agnostic library: to make it work properly, _your_ code would have to know when to yield or resume to the EM reactor's fiber, and then it starts to get ugly.)

Fieldset
--------
You'll encounter the **Crunch::Fieldset** class a lot when looking at other Crunch objects. It's a Hash subclass with some notable MongoDB-related differences:

* It's immutable. Once created, you can't change the keys nor their values. The object freezes itself on initialization, and common Hash methods that would change the contents will raise an exception.
* All keys are strings. If you initialize it with an ordinary hash, non-string keys will be converted to strings.
* The `.to_s` string conversion method returns the fieldset as a BSON binary string. 

Fieldsets are used throughout Crunch for any MongoDB action involving "a BSON document." (Which is most of them.) Query selectors, update operations, and many other attributes are Fieldsets.  The **Crunch::Document** class is a subset of Fieldset with a required *'\_id'* key and some extra behavior.

In most cases there's no need to create Fieldsets manually -- they're automatically generated from the parameters passed to the various Crunch methods.  Hashes are deeply recursed, and arrays become hashes with values of _1._ (A common MongoDB idiom.) You can also produce a Fieldset from a BSON string or byte buffer. If you ever need to make one, see the documentation.


Database
--------
The **Crunch::Database** class abstracts the communication with the server. There is one singleton Database object per Mongo database, and each maintains one or more server connections. Because it's a singleton, you invoke the instance with `.connect` rather than `.new`:

    db = Crunch::Database.connect 'babylon_5', host: 'example.org', user: 'zathras', password: 'n0tthe1'
    
If you call the `.connect` method again with the same database name, host, and port, you'll get the same Database object back.  If you change any of these parameters you'll receive a different Database object.

### Connection Pool ###

Each Database object maintains a private pool of connections to the server, and will scale them up or down based on the running size of the request queue.  These "connections" are just network constructs for dealing with EventMachine; don't confuse them with the top-level Connection class found in other drivers.  There's no public API to an individual connection.  However, you _can_ tune the Database's behavior in terms of pool size and rate of change.

The basic flow is a "grow quickly, shrink slowly" algorithm which works as follows:

1. The Database object is created with a minimum number of connections. (The default is 1.)
2. As your application asks for things from MongoDB, the requests are added to a queue managed by EventMachine.
3. Idle connections poll the request queue as often as the EventMachine loop lets them.  (Roughly a gazillion times a second.)  If there's a request waiting, a connection will take it and dispatch it immediately.
5. A "heartbeat" timer checks the size of the request queue periodically (the default is every second) to determine if there are too few or too many connections:
    * If the size of the queue is larger than the current number of connections, a new connection is added, up to the maximum allowed (the default is 10).
    * If the size of the queue has been smaller than the current connection count for _count**2_ heartbeats (i.e., the square of the number of connections) it closes a single connection and resets the counter.  This doesn't happen, of course, if the connection count is already at the minimum allowed.

The actual load will depend on your request pattern. Inserts, updates and deletes expect no reply (unless the **:safe** option is true) and the connection will immediately go back to the queue. Queries and 'safe mode' writes will occupy connections longer as they wait for a server response. A "write only" application could sustain a very high rate of small updates with only a single connection, whereas an application that's heavy on queries (or uses safe mode for all writes) would be more likely to grow the connection pool.  

You can check the size of the request queue with the `.pending_count` method, and the size of the connection pool with the `.connection_count` method.  If you find that the connection count is staying at maximum but your CPU and network bandwidth aren't close to 100% yet, you can safely adjust the `.max_connections` attribute at run time to raise the ceiling.

Note that the asynchronous nature of Crunch's connection pool necessarily breaks serialization. I.e., there's no guarantee that requests you send will be received by the server and processed in order. They'll be _queued_ in order, but if you have, say, an update containing 2 MB of data followed by one that simply increments an integer, it's quite likely that the second update will happen first on the server.  If this is a problem, your recourse is to set **:max\_connections** to 1.  (Or fix your business logic. Or use a database that supports transactions.)

### Options ###

There are two types of options to the `connect` method: _server_ options and _tuning_ options.  Server options can only be set using the `.connect` method, but can be read as attributes (except for **:password**) at any time.  Tuning options are read/write attributes of the object as well.

#### Server Options ####

These options are used for finding and authenticating to the database.  The _name_ of the database is of course a server attribute as well; however, as the only required parameter, it isn't part of the options hash.

* **:host** _(String)_ The IP address or DNS name to connect to.  Defaults to _localhost_.
* **:port** _(String)_ The port for all connections.  Defaults to _27017_ per Mongo canon.

Note that authentication and connecting to replica sets or pairs are not supported. _Yet._ It'll come.

#### Tuning Options ####

You can set the pool size and growth/reduction rate with the following options:
 
* **:min\_connections** _(Integer)_ Always maintain at least this many connections. Defaults to _1_.
* **:max\_connections** _(Integer)_ Don't grow the pool past this size. Defaults to _10_.
* **:heartbeat** _(Integer, Float)_ Interval in seconds at which to perform connection maintenance. Defaults to _1_.


Query
-----
The **Crunch::Query** class retrieves data from the database and presents it as an Array-like Enumerable. Unlike many other database libraries, basic Crunch queries are _immediate_ and _immutable_.  They'll ask the server for a cursor the moment they're instantiated (unless you flag them not to) and any changes made to retrieved data won't be reflected until you make another query. The server request is always asynchronous. Synchronous delays will only occur if you try to _read_ the data before it comes back -- and you can still avoid them by passing a block.

This design enables speed (the data's on its way before you start to look at it) and simplicity (the cursor itself is an internal detail hidden from the API). MongoDB never guarantees transactional isolation, but Crunch timestamps every server response, so you can know how stale your data might be and whether a refresh is needed. You never reload data in place; you simply clone the query and get the data again. Several other base classes use Queries under the hood.

### Creation ###
You can create a Query in several ways, depending on how much work you already want done for you. The options hashes in the examples below may not make sense immediately; it'll be covered shortly.

#### Directly ####
Pass a Collection object in the first parameter, and then any options or query selectors as a hash.  So:

    db = Database.connect 'babylon_5'
    collection = db.collection :characters
    query = Query.new collection, 'species' => 'Vorlon', :limit => 1
    query.first['name']   #=> 'Kosh'


#### From a Collection ####
The Collection object has a `.query` method as a shortcut to the above. This time you only have to worry about your options hash:
    
    query = collection.query 'characters', 'role' => 'Commander', 'name' => /J.+ S.+/, 'messianic' => true
    query.collect {|c| c['name']}   #=> ['Jeffrey Sinclair', 'John Sheridan']
 
#### From Another Query ####
Queries can spawn other queries. The new query inherits all the options of its parent, which can be added to or overridden:

    first_query = collection.query 'has_hair' => true
    first_query.collect {|c| c['species']}  #=> ['Human', 'Centauri'] 
    
    second_query = first_query.query 'sex' => 'female'
    second_query.collect {|c| c['species']}  #=> ['Human']  (Centauri women are bald)
                                             #              (includes post-season-2 Delenn as a technicality)
    
### Retrieval ###
The Query object is a self-contained capsule of data -- it contains both the question (via its initialization parameters) and the answers (via accessors).  For example:

    query = Query.new db, 'musicians', 'band' => 'The Beatles'
    query.first  #=> <Document> {'_id' => [...], 'name' => 'John Lennon', ...}
    query.next   #=> <Document> {'_id' => [...], 'name' => 'Paul McCartney', ...}
    query[2]     #=> <Document> {'_id' => [...], 'name' => 'Ringo Starr', ...}
    query.any? {|beatle| beatle['name'] == 'Yoko Ono'}  #=> false

Each item returned is a Document object (see below).  The interesting Query methods to get to them are summarized below; most of the other access behavior comes from the standard Enumerable mixin: 

* `[]` - Returns the Document at the given index. If the data retrieval hasn't gotten that far yet, the method will block until it does. (_Note:_ Don't make the mistake of confusing Queries for Arrays just because of this bracket thingy. This is not duck typing; most other array methods won't work.)
* `.at` - A non-blocking accessor. Accepts an index like `[]` and a block of code, and will pass the document to the block upon retrieval. The return value is a proc that will return _false_ when called if the code has not yet been executed, _true_ if it has been, and raise any exceptions that arise during execution.
* `.get` - Returns a document with a specified *'\_id'*.  Faster than the `[]` index accessor if you know what you're looking for.  Non-blocking; if the specified document has not been retrieved for this query, it will simply return _nil._
* `.first` - Returns the first document of the result set. If the data retrieval hasn't pulled the first record yet, the method will block until it does. (Call `.ready?` beforehand to avoid this blocking.)
* `.last` - Returns the last document in the result set.  This requires traversing the entire cursor, so if the data retrieval is not yet complete, the method will block until all records have been loaded. (Call `.complete?` beforehand to avoid this blocking.)
* `.each` - Steps through the entire result set. When given a block of code, passes each document to it, and will wait synchronously until the entire run is completed. If no block is given, returns an Enumerator so that you can call `.next` and friends at your leisure.
* `.each!` - An asynchronous form of `each` that runs the provided block on each document in the EventMachine loop. Returns a proc that wil return _false_ if the iteration is not yet complete, _true_ if it is complete, and raise any exceptions that arise during execution.
* `.size` - Returns the _current_ number of documents that have been loaded. See _Size vs. Count_ below.
* `.total_size` - Loads the complete record set, then returns the final number of documents. See _Size vs. Count_ below.
* `.count` - Returns the number of documents in the query as reported by MongoDB. Will likely block for a short period unless the **:count** option is set upon initialization. See _Size vs. Count_ below.
* `.ready?` - Returns _true_ if the first document in the result set has been loaded.
* `.complete?` - Returns _true_ if every record in the result set has been loaded.
* `.has?` - Takes an index and returns _true_ if the record at that position in the result set has been loaded.

All of these methods are thread-safe and as consistent as MongoDB will allow them to be. The actual cursor is a hidden property owned by the database object, so that it can be explicitly closed if the query is garbage collected before completion.

#### Lookahead ####

The two hazards of traversing a large query in MongoDB are memory usage and speed.  If space and time weren't issues, we'd load every record into an array immediately for full random access.  In the real world this is often practical for smallish result sets, but a Ruby array of millions or billions of documents would bring your application to its knees.  It's also not always necessary.  Some use cases require random access, but sometimes you just want to step through each record once and be done with it.

Crunch provides two facilities to balance these constraints.  The first is the _lookahead_ system.  Mongo cursors deliver documents in batches.  (The default is 100, but this can be configured with the **:batch** option.)  Crunch tries to stay a little ahead of your document access by making `GETMORE` calls to the server for the next batch before it's needed.  By default it runs one batch ahead, so the flow of data runs something like this:

1. The Query fires a message off to the server as soon as it's created. We're using EventMachine, so nothing else happens until the server responds.
2. The server's reply contains a cursor ID and the first 100 documents.  The Query parses these records in the background and stores them in an internal array, where they wait for your application to read them. 
3. As soon as document #1 is accessed -- or any of them -- the Query requests the next batch (documents 101 to 200). When the batch is received, they are silently added to the array. Ideally this process will be complete before you need them.
4. When document #101 or later is accessed, the Query requests the _next_ batch (201 to 300) and processes them.
5. Rinse, repeat.

If running a hundred documents ahead isn't enough (perhaps because your code's too fast) you can set a higher integer value for the **:lookahead** option on query creation.  A value of 2 would try to stay _two_ batches ahead of your data access, et cetera.  Low values will help limit memory usage when combined with no or weak retention (see below), as Crunch will only need to reserve memory for a few hundred records at a time.

The **:lookahead** option also accepts two special non-integer values.  The _:none_ value disables advance retrieval; no batch will be requested until there is an access attempt on one of its documents.  This usually means more waiting, but may reduce network traffic if you aren't even sure you'll need the data.

The _:all_ value is a 'greedy' lookahead -- it will request and store all documents from the result set as quickly as it can, regardless of data access.  This minimizes synchronous waiting, but can also cause massive memory allocations and freeze-ups if the result set is unreasonably large.

#### Retention ####

The other facility for managing memory is the _retention_ system.  Every document retrieved will be held in memory until it is accessed.  What happens to it _after_ access can be configured for your application's needs by using the **:retain** option.

A **:retain** value of _:all_ will act pretty much like a standard array.  The query will hold onto every document, and no memory will be released until the query itself goes out of scope and is garbage collected.  Use this option if you expect heavy random access or if you need to iterate through the same results more than once.

A value of _:none_ will retain each document until it is accessed, and then clear it by setting the internal array element to _nil._  You will be unable to access documents more than once unless you store them someplace outside the Query object.  This can be very memory-efficient when combined with a low **:lookahead** value. Use this option if you expect to iterate through the result set exactly once.  (It's set by default when you pass a block to the query constructor.)

The default behavior is what we lovingly call _semi-weak retention_.  Crunch will attempt to balance random access and memory efficiency by remembering _some_ documents and providing fallback retrieval for the rest.  You enable this behavior by setting **:retain** to a positive integer (the default is 10,000).  If your result set is smaller than this, you'll be able to iterate or access any element as often as you want.  If you access more documents than the **:retain** size, the _earliest_ documents you accessed will become eligible for garbage collection.  Accessing a deleted document again will retrieve it from the MongoDB server with a single-document query.  Your application will block, of course, while it's retrieved.

The details of this retention mechanism are complex, involving weak references and LRU queues; we won't dive into them here.  What matters is that repeated access or iteration _will always work_, even on the largest result sets, but once you exceed a certain size it may become horribly, horribly slow.  You'll revert to retrieving each document from the server again one at a time.  It could also break the query's immutability model, because a document retrieved a second time might have changed.  We pay these prices to keep your memory usage from exploding.

In summary, some rules of thumb:

* If your expected number of documents from a query is low to moderate (less than 10,000), don't worry about the retention system.  Things will Just Work.
* If you expect a large number of documents but will only need to look at each one once, use **:retain => :none**.
* If you expect a large number of documents and will need to access them randomly and repeatedly, either use **:retain => :all** or assign them to your own variables.
* If you expect a large number of documents and will need to iterate through them in order multiple times, either use **:retain => :all** or clone the query and run it again.  (Querying again is a better idea if you can handle the data possibly changing.)

#### Size vs. Count ####

Here's a quirk of MongoDB that'll drive some SQL people nuts: it isn't consistent.  There's no transactional isolation.  If relevant documents are added, deleted, or updated while your query is running, you _might_ see the changes and you might not.  Crunch's internal storage avoids the rare edge case of getting the same document twice (the earliest version is canonical), but it's still impossible to know beforehand exactly how many documents you'll get or how fresh they'll be if they keep changing.  If this is a deal-breaker for you, Mongo's likely the wrong database.

Crunch provides two ways of telling you how many records you have.  The `.size` method returns the number of documents retrieved so far.  Thus, the number will keep changing until the record set is fully retrieved.  A synchronous `.total_size` method provides the final number by calling `.last` and waiting -- providing accuracy at the expense of time and memory.

The `.count` method uses a MongoDB server command to calculate the number of documents returned by the query.  It requires a separate round trip and is therefore synchronous, but you can save time by setting **:count => true** on query creation (which requests the count _before_ the query itself).  The `.count` method offers the strong advantage of giving you a number without having to retrieve any documents; however, it is not guaranteed to be accurate.  Changes to the data could raise or lower the number of documents returned by the query, so it's unsafe to rely on this number except for approximate scaling or progress purposes.

### Updating ###
Queries have an `.update` method that takes a hash of atomic change operators:

    my_query.update set: {'foo' => 'bar', 'zoo' => 'zar'}, inc: {'looky' => 1}, addToSet: {'dwarves' => 'Grumpy'}

This is really just a shortcut for convenience; it passes things along to its Collection object's `.update` method along with its own query conditions.  It takes the same options and returns the same way.

Likewise, there's a `.delete` method that shortcuts to the Collection, instructing it to remove any records matching the query's conditions.

Remember that the Query itself is _immutable_ -- you won't see any changes reflected in its own data, but rather in subsequent queries. Don't get tripped up by this.


### Options ###
Because Queries are immutable, all options must be passed at initialization.  Only the **collection** parameter is required; a query without a hash simply returns the entire collection. 

The options hash may contain both search conditions and defined options, mingled interchangeably.  Known options are removed first, and then any key that the Query class doesn't recognize as an option is passed to MongoDB as a search condition.  To avoid confusion and name collisions, we _strongly_ suggest using strings for search conditions (all options are symbols), or else use the explicit **:conditions** option to separate them:  

    highways = db.collection 'roads'
    highways.query 'limit' => 70, :limit => 5           # Returns the first 5 roads with a speed limit of 70
    highways.query conditions: {limit: 70}, limit: 5    # The same (using Ruby 1.9 hash syntax)
    
#### MongoDB Options ####
The following options are defined by the MongoDB server and passed along in the query message:

* **:conditions** _(Hash)_ Explicit search conditions. See above.
* **:fields** _(Array)_ Only return these document fields.  (*'\_id'* is always included.)
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
* **:lookahead** _(Integer, :none, or :all)_ Load data _N_ batches ahead of data access. Defaults to 1.
* **:retain** _(Integer, :none, or :all)_ Whether to keep document references after access. Defaults to 10,000.
* **:count** _(Boolean)_ Retrieve the document count for this query in a separate request. Saves time if the `.count` method is called later. Defaults to false.

#### Blocks and Block Options ####
Hard-core asynchronists can skip in-line interaction with the Query entirely and specify callbacks to operate on the data in the EM loop.  If a block is passed to `Query.new` or any of the various `.query` methods, it is automatically called by EventMachine on each document in the result set in turn:

    cartoon_characters.query 'type' => 'Care Bear' do |bear|
        puts bear['name'] + ': ' + bear['cheesy_symbol']
    end

Passing a block implicitly sets **:retain** to _:none_ for memory conservation, but you can override this if you want to hold onto the data for your own purposes. 

For more refinement, you can pass procs or lambdas to the following query options:

* **:on\_each** _(Proc)_ Identical to the method block behavior described above.  Useful for clarity if you're also going to use any of the options below.
* **:on\_error** _(Proc)_ Called on query failure. Passes the query and an exception object as parameters to the proc.
* **:on\_ready** _(Proc)_ Called once the first document is loaded into memory. Passes the query as a parameter. Useful if you want to avoid synchronous delays while waiting for the server to process.
* **:on\_completion** _(Proc)_ Called once the last document is loaded into memory. Implicitly sets **:lookahead** to _:all_ unless overridden. Passes the query as a parameter. Useful if you want to do something to the entire enumerable _other than_ stepping through it. (Don't use for huge result sets!)
* **:on\_retrieval** _(Proc)_ Called after each cursor return.  Passes the query and the index of the first document in the relevant batch as parameters. Useful if you want to display progress or avoid synchronous delays from the network.


Collection
----------
The **Crunch::Collection** class is the hook that data itself hangs from.  Every Query and Document belongs to a Collection, and relies on it for message generation to the server.  It also provides methods for inserting or updating documents, managing indexes, etc.  Through delegation, it can be treated as a Query, and the documents within it can be iterated or accessed.

**NOTE:** Not every Collection instance method is described in this section. The `.get` and `.create` methods are described in the **Crunch::Document** section because they return single Document objects. And the `.prior`, `.post`, `.push` and `.pop` methods are described in the **Finding and Modifying** section because they require some explanation. 

### Creation ###
Like Database objects, Collection objects use the _singleton_ pattern.  A particular named collection in a particular database will have _one_ object representing it.  The explicit way to create this object is with the Database's `.collection` method:

    collection = my_database.collection 'characters', count: true, run: true, refresh: 60

The Collection may also be created at the first reference to its name within a Query or Document constructor.  Once created, any further references or calls to `.collection` will return the same object again, and any options will alter the Collection's properties.  (Unlike Documents or Queries, Collections are _not_ immutable.)

### Implicit Query ###
It's a very common use case to access or iterate through all the documents in a collection.  Creating a separate Query object with no search conditions is simple enough, but it's one more object for your application to manage.  Crunch simplifies things by allowing each Collection object to have an _implicit query_, and exposing all of the query's methods via delegation:

    collection = my_database.collection 'characters'
    collection.ready? #=> false  (The query won't run until the first data access)
    collection.first  #=> {'_id' => [...], 'name' => 'John Sheridan', 'species' => 'Human', 'messianic' => true, ...}
    collection[5]     #=> {'_id' => [...], 'name' => 'Susan Ivanova', 'species' => 'Human', 'is_god' => true, ...}
      
Unlike ordinary queries, the implicit query's **:run** value defaults to _false_.  This means that the query won't actually be executed until the first time it's needed.  This is sensible, since it's very probable you won't use it at all, but you can override it to _true_ if you want data to be available shortly after the Collection is created.

You can also _refresh_ the implicit query to bring the Collection's contents up to date.  This works in practice by replacing the old query with a new one.  You can trigger it manually with the `.refresh!` method, or you can set the **:refresh** option or `.refresh` attribute to a positive integer value.  This produces an EventMachine periodic timer that replaces the implicit query with a new one every _N_ seconds.  (It's probably a bad idea to override the **:run** option to _true_ for a periodic timer.)

If you decide to use periodic refreshes, please keep the consequences in mind.  It means documents and their order _can and will_ change in the background; so calling, say, `collection[5]` could return a different document between one call and the next.  Don't try to manually iterate through the records using their indexes, because the set of things you're looking at could change at any time.  Enumerators and code blocks are safe, however; they'll continue to refer to their original Query object and its contents even after the Collection has dropped it from scope.

Confused?  Don't overthink it.  If all this implicit delegate stuff seems too gonzo, you can forget the whole idea and get a standalone Query object representing the entire collection:

    collection.query
    
### Inserting ###

Inserting a single document is very simple:

    collection.insert 'name' => "G'Kar", 'species' => 'Narn', 'hair' => false, 'paraphrases' => 'Socrates'
    
You can pass a Fieldset object or a hash (which will be implicitly converted to a Fieldset).  If you don't specify an *'\_id'* field, Crunch will create one before sending the document to the server.  The *'\_id'* is also the return value of the `.insert` method so that you can retrieve the document or link to it as needed.

You can also insert multiple documents at once:

    collection.insert {'name' => 'Londo Mollari'}, {'name' => 'Vir Kotto'}
    
The return value in this case is an array of the documents' *'\_id'* values.

#### Safety ####

The `.insert` method respects the value of the `.safe` attribute at the module, Database, or Collection levels, or via the **:safe** option to the method call:

    collection.insert 'name' => 'Morden', safe: true      # (Irony.)

If safety is _false_ (the default) the method will return immediately, leaving EventMachine to handle the actual _'INSERT'_ message in the background.  If safety is _true_ the method becomes synchronous, and blocks until the insert is sent and a _getLastError_ request has been answered.  If there are no errors, the *'\_id'* value(s) will eventually be returned as described above.  If an error occurs, a **Crunch::IndexError** exception will be raised with the details.

### Deleting ###

Unsurprisingly, deleting looks a lot like inserting:

    collection.delete 'role' => 'redshirt', multi: false, safe: true
    
The main hash (i.e., everything except options) represents the search conditions specifying which documents to delete. If no conditions are given, every document in the collection will be deleted. (Caveat applicator!)

The return value is not meaningful in 'unsafe' mode. If called with the **:safe** option it will return the number of documents deleted, or a **Crunch::DeleteError** exception if an error occurs.   
    
Options:

* **:multi** _(Boolean)_ - if _true_, will delete every document matching the conditions. If _false_, will only delete the first document found. Defaults to _true_. (The more common use case in the author's brash opinion. Differs from the 'official' MongoDB default, so beware!)
* **:safe** _(Boolean)_ - see above.


### Updating ###

Updating documents looks like querying on them for the most part:

    collection.update 'species' => 'Vorlon', set: {'religious_iconography' => true}, multi: true, upsert: false

The main hash (i.e., everything except options) represents the search conditions specifying which documents to update. If no conditions are given, the entire collection will be updated. The update values are passed as options. 

The return value is not meaningful in 'unsafe' mode. If called with the **:safe** option it will return the number of documents updated, or a **Crunch::UpdateError** exception if an error occurs.
    
#### Control Options ####

The following options are simple flags controlling MongoDB's behavior:

* **:multi** _(Boolean)_ - if _true_, will update every document matching the **:query** conditions.  If _false_, will only update the first document found. Defaults to _true_. (The more common use case in the author's brash opinion. Differs from the 'official' MongoDB default, so beware!)
* **:upsert** _(Boolean)_ - if _true_, will create a new document matching the **:query** conditions if no matching documents are found. Defaults to _false_. (Also see the `.push` method, which will return the document itself.)
* **:safe** _(Boolean)_ - see above.

#### Update Options ####

For more information on all of the following, see the [official MongoDB documentation](http://www.mongodb.org/display/DOCS/Updating):

* **:document** _(Hash, Fieldset)_ - replace the entirety of a single matching document with the given fields. Implicitly sets **:multi** to _false_ (and will throw a **Crunch::UpdateError** if you try to override it). Rarely useful outside the traditional `Document#save` context.
* **:set** _(Hash, Fieldset)_ - sets the given fields to the given values.
* **:unset** _(String, Symbol, Array)_ - takes a field name or a list of names and removes each one.
* **:inc** _(String, Symbol, Array, Hash, Fieldset)_ - if given a hash or fieldset, increments each key by each value. If given a field name or list of names, increments by an implied value of 1.
* **:push** _(Hash, Fieldset)_ - appends the given values to the arrays named by the given keys.
* **:pushAll** _(Hash, Fieldset)_ - like **:push**, but with arrays of values. See the Mongo documentation.
* **:addToSet** _(Hash, Fieldset)_ - appends the given values to the given arrays _if_ they don't already exist.
* **:addAllToSet** _(Hash, Fieldset)_ - like **:addToSet**, but with arrays of values. (_Custom:_ does an implied `$each`.)
* **:pop** _(String, Symbol, Array, Hash)_ - given an array name or a list of arrays, removes the last element from each. Given a hash, removes the last element for values of _1_ or _:last_ or the first element for values of _-1_ or _:first_. See the Mongo documentation if you need to mix 'last' and 'first' behavior, or use the next two bullet points. 
* **:pop_last** _(String, Symbol, Array)_ - removes the last element from each array name or list of arrays. (_Custom:_ syntactic sugar for **:pop**.)
* **:pop_first** _(String, Symbol, Array)_ - removes the first element from each array name or list of arrays. (_Custom:_ syntactic sugar for **:pop**.)
* **:pull** _(Hash, Fieldset)_ - removes the given values from the arrays named by the given keys.
* **:pullAll** _(Hash, Fieldset)_ - like **:pull**, but with arrays of values. See the Mongo documentation.
* **:rename** _(Hash, Fieldset)_ - changes the given field names to the given values.
* **:bit** _(Hash, Fieldset)_ - performs the bitwise updates from the values on the given fields. See the Mongo documentation.


Document
--------
The **Crunch::Document** class is the object you get when you iterate through a Query or Collection. It allows MongoDB documents to read, update, or delete themselves on an individual basis.  It's a subclass of **Crunch::Fieldset** with additional restrictions:

* It _must_ be created from a BSON binary string or byte buffer.
* It _must_ have a Collection attribute.
* It _must_ have an _'\_id'_ key. (Also accessible by the `.id` attribute.)

The assumption is that a Document represents a real entity _already existing_ in the Mongo database. An unsaved document is not a Document. You shouldn't create these from scratch; the `.new` method is not part of the public API.

### Retrieval ###

Documents are retrieved from Collections using the `.get` method.  You can pass the document's ID or a hash of query options:
    
    id = Crunch.oid '4c14f7943f165103d2000015'  # Makes a BSON ObjectId from a string
    doc = my_collection.get id                  # Retrieves the document with that ID
    doc = my_collection.get 'name' => /Joe/, 'age' => {lt: 35}  # Returns the first matching document
    doc = my_collection.get 'name' => /Joe/, fields: ['name', 'age']  # ...also limits fields returned
    
Behind the scenes, the `.get` method is simply creating a **Crunch::Query** and then returning the single record that comes back.  It accepts the **:conditions**, **:fields**, **:skip** and **:sort** options as described in Query.  It does _not_ accept the **:limit** option; the query has an implicit limit of _-1_ and you can't change it. (The negative number prevents the Mongo server from creating a cursor.)
   
#### Asynchronous Retrieval ####

Single-document retrievals are synchronous by default: the `.get` method will block until the data has been returned from MongoDB.  Failures will return an exception from the method.  To work with a single document without blocking, you can pass a block to be executed on the document once it's retrieved:

    status = my_collection.get 'first_name' => /Joe/ {|doc| do_something}

The return value is a proc that will return _false_ when called if the code has not yet been executed, _true_ if it has been, and raise any exceptions that arise during execution.

### Creation ###

The roundabout way to make a new document is to run the `.insert` method of the appropriate Collection and then call `.get` to retrieve the returned document *'\_id'*:

    id = dwarfs.insert 'name' => 'Sleepy'   #=> BSON::ObjectId('4d5f25d5a2790e024b000001')
    doc = dwarfs.get id     #=> <Document> {'_id' => BSON::ObjectId('4d5f25d5a2790e024b000001'), 'name' => 'Sleepy'}

But hark!  There's a `.create` method on the collection that will do it in one (synchronous) step:
    
    doc = dwarfs.create 'name' => 'Sleepy'    #=> <Document> {'_id' => BSON::ObjectId('4d5f26d2a2790e024b000002'), 'name' => 'Sleepy'}

Technically, the `.create` method works using a **findAndModify** upsert with a newly generated ID rather than a separate insert and retrieval. But it works the same. Don't worry about it.

### Updating ###

Documents are immutable, so you can't update the object itself. But you _can_ send changes to the database for future generations:

    doc.update set: {'phasers' => 'stun'}, inc: 'cliches'
    
The method is just a shortcut to the `Collection#update` method, so all of the same update options apply.  (Including **:document**, if you want to replace the entire contents of the document.)  The **:multi** and **:upsert** options are not valid for obvious reasons. 

Like the Collection method, `.update` is asynchronous and does not return a meaningful value unless you set the **:safe** option to _true._

### Deleting ### 

You can tell the database to get rid of the document with a simple command (which is, again, a shortcut to the Collection method):

    doc.delete
    
There are no options except for **:safe**.  Like the Collection method, `.delete` is asynchronous and does not return a meaningful value unless you set the **:safe** option to _true._

Will `.delete` cause any changes to the object you're looking at?  No.  Repeat after me: ***Documents are immutable.***  You can turn the object into a ghost, but it will look just as solid.


Finding and Modifying
---------------------
If you've read the MongoDB doc site (and you should), you've likely been flummoxed by the **findAndModify** command.  It's the database's most powerful and most confusing feature: it sweeps every aspect of CRUD into one übermethod, like a sort of addled Voltron. Here's my nutshell attempt to make sense of it:

1. You can give it some query conditions. The _first_ matching document in the collection, if any, is used for Step 2. (You can also create a new document if nothing matches.)
2. You can change the document's contents, or delete it entirely.
3. You'll receive the document, or a subset of its fields, _before or after_ its contents were changed. You get to decide; you can't have both.

It's the _before or after_ part that causes brains to melt. By default it's _before_ -- which is useful if, say, you're popping something off of an array field. But if you're adding new data or incrementing, you probably want the _after_ version that includes your changes. In this author's opinion, putting both in one method was a mistake. It doesn't matter which one's the default; a Principle of Least Surprise violation is inevitable.

Crunch resolves all this chaos by breaking **findAndModify**'s use cases into a few different methods. The `.create` method was already described in the **Crunch::Document** section above. (It's really just a special case of `.push`.) The rest are described below. They all share the following characteristics:

1. They're instance methods of **Crunch::Collection**.  
2. They're semantically similar to the `Collection#update` method. They take the same query conditions and update options. (But not the **:multi**, **:upsert** or **:safe** options.)
3. They're synchronous and return a Document if you don't give them a block.
4. If you _do_ give them a block, they're asynchronous and pass the document to the block. The return value is a proc that will return _false_ when called if the code has not yet been executed, _true_ if it has been, and raise any exceptions that arise during execution.

### .push ###

This is the "upsert" variant of **findAndModify**:

    collection.push 'name' => 'John Sheridan', push: {'places' => "Z'ha'Dum"}   #=> <Document> {...}

The `.push` method looks for the first document in the collection matching the query conditions, and if found, applies the update options to it.  If a document is _not_ found, it creates one based on the query conditions and then applies the update options.  Either way, the document is returned as it exists _after_ the update.  (Insertions wouldn't make much sense otherwise.)  

Do not confuse the method name `.push` with the **:push** atomic update operation, which appends a value to an array field.  We've named this method `.push` because upserts can be useful in set- or stack-like operations, and because it goes well with the next method.      

### .pop ###

This is the "remove" variant of **findAndModify**:

    collection.pop 'role' => 'redshirt'     #=> <Document> {'name' => 'Security Guard #5', role => 'redshirt', ...}
    
The `.pop` method looks for the first document in the collection matching the query conditions, tells MongoDB to delete it, and returns the document that was just deleted. It returns _nil_ if no document was found. The _before_ mode of **findAndModify** is implied for obvious reasons.

Do not confuse the method name `.pop` with the **:pop** atomic update operation, which removes an element from an array field (but doesn't return anything by itself).  We've named this method `.pop` because of its obvious usefulness in stack- or queue-like operations.  Without something like this **findAndModify** variant, it'd be very difficult to use a MongoDB collection reliably as a work queue.

### .prior ###

This is the "return _before_ update" variant of **findAndModify**:

    collection.prior 'name' => 'John Sheridan', 'places' => "Z'ha'Dum", 'deaths' => 0, inc: 'deaths'
        #=> <Document> {'name' => 'John Sheridan', 'places' => ["Babylon 5", "Z'ha'Dum", ...], 'deaths' => 0, ...}

The `.prior` method looks for the first document in the collection matching the query conditions, retrieves it, and then applies the update options to it. The method returns _nil_ if no match was found; otherwise, the document returned will contain the contents from _before_ the update. This is often essential when using atomic updates that destroy data like **:pop** or **:pull** -- at least if you need to know what was removed.  

Do not confuse the method name `.prior` with Richard Pryor.

### .post ###

This is the "return _after_ update" variant of **findAndModify**:

    collection.post 'name' => 'John Sheridan', 'places' => "Z'ha'Dum", 'deaths' => 0, inc: 'deaths'
        #=> <Document> {'name' => 'John Sheridan', 'places' => ["Babylon 5", "Z'ha'Dum", ...], 'deaths' => 1, ...}

The `.post` method looks for the first document in the collection matching the query conditions, applies the update options to it, and then retrieves it. The method returns _nil_ if no match was found; otherwise, the document returned will contain the contents from _after_ the update. This can be very useful for counter-type operations, or other cases where a transformation is occurring on existing data.  

Do not confuse the method name `.post` with the HTTP or REST sense of 'posting information.'  The implied meaning here is strictly temporal, and the `.post` method _only_ updates existing records.  If you want to 'post' a new record, consider either the `.push` method (which is the same thing with the _upsert_ option turned on) or the `.create` method (which always produces a new document).



