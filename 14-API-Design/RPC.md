RPC: Remote Procedure Calls. Its the ability of the client application to execute a subroutine on in a remote server. This remote method invocation looks like calling a normal local method in terms of the developer code. This is also called local transperancy. To the developer of the client application a method executed locally or remotely looks the same.

RPC supports multiple programming languages. Applications written in different programming languages can talk to each other using RPC.

The 3 components of RPC are
1) Interface Descriptions Language(IDL)
2) Client Stub
3) Server Stub

How RPC works
============= 
1) The api as well as the data types are declared using special description language. 
2) We will have a server stub & a client stub(Auto generated). 
3) Client Stub ecodes the data & initiates connection to remote server stub. 
4) Server stub deserializes the data. 
5) Real invocation of the method takes place, data is deserialized, result is sentback to server stub. The Server stub serializes the data again and sends it back to client. 
6) Client deserializes received response.  

Benifits
========
Conveniece to the developers of the client application. They can communicate with our system easily by calling methods on objects similar to calling normal local methods.
The details of communication establishment or data transfer between client to server are abstracted away from the developers.
Failures in communication with server result in an error or exception

Drawbacks
=========
1) Remote methods are slower & less reliable. They introduce performance bottlenecks. Slowness can be addressed by using asynchronous processing.
2) There is no real way for the client to know whether the server received the message and the acknowledgment message got lost in the network or the server crushed and never received the message. To mitigate this we need make the operations idempotent when possible.

When to use RPC
===============
Frameworks that support RPC from frontend clients are less common.
Its a good choice when we are providing API to a different company instead of an end user app or a web page.
Communication between different components within a large system.
Abstract away the network communication and focus only on the actions the client wants to perform

When not to use RPC
===================
1) When we dont want to abstract the network the communication
2) When we want to take direct advantage of HTTP cookies or headers

Summary
=======
RPC revolves more around actions and less around data/resources
In RPC, every action is a new method with a different name and signature
We can define many methods/actions without limitation

Other styles of api are a better fit when
Designing an api that is more data-centric
All the operations needed are simple CRUD(Create, Read, Update, Delete) operations
