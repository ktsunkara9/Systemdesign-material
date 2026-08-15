Introduction
System = Behavior + Interface(API)
The Interface is a contract between Engineers who implement the system and Client Applications who use the system
Since this interface is called by other applications it is referred to as an application programming interface or API.
API is called by other applications remotely through the network.
The applicatoins can be
1) Front End Clients like mobile apps or Web Apps
2) Internal systems within our organization
3) Backend Systems of other companies
Each component of our system will have its own API.
The component API's will be called by other applications within our system.

API Categories
==============
APIs are classified into 3 groups
1) Public APIs
    Exposed to General Public.
    Any developer can use/call them from their application.
    Best practice would be to have the users register with us before allowing to send requests and use the system so that we'll have control over who uses the system externally, how they use the system, better security, blacklist users breaking rules.

2) Private APIs
    Exposed only internall within the company.
    They allow other teams/parts of the organization to:
        a) take advantage of the system
        b) provided bigger value for the company
        c) Not expose the system directly outside the organization

3) Partner APIs
    Similar to Public APIs
    Exposed only to companies/users having business relationship with us. The business relationship is in the form of customer agreement after buying our product or subscribing to our service.

Benifits of well designed API
=============================
Client who uses it can immediately and easily enhance their business by using our system.
They need not know anything about our system's internal design/implementation.
Once we define and expose our API, clients can integrate with us without waiting for full implementation of our system.
API makes it easier to design and architect the internal structure of our system. It defines the endpoints to the different routes that the user can take to use our system.

Best Practices and Patterns
===========================
1) Complete Encapsulation of the internal design & implementation abstracting it away from the developer who use it.
2) API should be completely decoupled from our internal design and implementation so that we can change the design later without breaking the contract with the client.
3) Easy to Use, Easy to Understand and Impossible to misuse. There should only be one way to get certain data/perform a task. Descriptive names for actions and resources. Exposing only the information and actions that users need.
4) Keeping operations idempotent as much as possible.
    ex: updating user's address to a new address is an idempotent operation as the result is same regardless of performing it any number of times
5) API Pagination
    Let clients request ony a small segment of the response
    Specify maximum size of each response from our system
    Specify an offset within the overall dataset
    To recieve the next segment increment the offset
6) Asynchronous operations : The client recievs response immediately with a way to check status
    examples: Running a big report requiring our system to talk to many databases
    Big data analysis that scans a lot of records/log files
    Compression of large video files
7) Versioning the APIs: we can maintain to versions of the api at the same time and deprecate the older version gradually.
