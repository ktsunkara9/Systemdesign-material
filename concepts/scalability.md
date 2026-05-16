Scalability: Its the measure of a system's ability to handle a growing amount of work(features), in an easy and cost effective way by adding resources to the system.

The load/traffic never stays the same. It can follow different patterns.
seasonal
Viral Posts or news
Weekdays vs weekends
Time of the day - day time vs night time

In the long run if our business is doing well we can expect more traffic & load as more users are using our system.

Linear Scalability: Linear scalability means "If we double the amount of resources we can handle double the amount of work". But its very hard to achieve linear scalability.

Peformance also depends on how the system scales.

We can scale our systems in 3 ways.

Vertical Scalability: Adding resources or upgrading the existing resources on a single computer to allow our system to handle higher traffic or load.

To handle more number of users we move our application to a superior system with more memory, cpu, network card(which can handle higher bandwidth). We can upgrade the db to something that have more storage capacity.

Pros:
Any application can benifit from it
No code changes required
Migration between machines is very easy

Cons:
Scope of upgrade is limited
We are locked to a centralized system which cannot provide High Availability, Fault Tolerance.


Horizontal Scalability: Adding more resources in a form of new instances running on different machines, to allow our system to handle higher traffic or load.

Instead of upgrading existing hardware we add more resources.
ex: more instances of ec2, db instances.

Pros:
No limit on scalability
Its easy to add/remove machines
If designed correctly we get High availability and Fault Tolerance

Cons: 
Initial code changes are required
Increased complexity and coordination overhead



Team/Organizational Scalability:
In general we get more productivity with more engineers in the team, but at somepoint the more engineers we have the productivity will be less if we are working on a monolithic system if they are all working on same code base.

cons:
Many crowded meetings
code merge conflicts
business complexity - the developers will take lot more time to learn all things if everyting is developed in a single monolith.
Testing is harder and slower
Releases become very risky and less frequent

Software Architecture impacts engineering velocity (team productivity).

Summary: