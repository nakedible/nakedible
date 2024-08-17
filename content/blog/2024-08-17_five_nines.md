+++
title = "Achiving 99.999% availability for an API on AWS"
date = 2024-08-17

[taxonomies]
categories = ["cloud"]
+++

Building a highly available global service is a challenge that many architects
will need to tackle at some point in their careers. Yet, there's surprisingly
little concrete guidance on the internet how to do achieve it. Even more, most
of the guidance is around securing something stateless like web page serving,
instead of a stateful API service.

This article aims to explain how to concretely set up a 99.999% (five nines) and
beyond API service utilizing AWS.

Designed-for availability vs. reliability in general
----------------------------------------------------

Real world availability is much more than just a numbers game. There are a huge
number of aspects to reliability in general, such as operational excellence,
change automation, security, scaling, disaster recovery, etc. The three biggest
reasons you are going to have downtime is due to operational mistakes, botched
changes and software problems. And by software problems I mean things where the
service is fully up at some point, and the next it's not, because some counter
overflowed, some parameter got set by a user, some certificate expired, etc.
These are not the focus here and the [AWS Reliability
Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
does a pretty good job of discussing them.

We are going to focus on achiving a design that can reach five nines or more of
availability by [calculating the
availability](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/availability.html)
of the design based on the availability of its components. This is basically the
aggregate failure chance of the infrastructure components used to build the
design. However, simply relying on a calculation might lead us into a solution
that looks good on paper, but performs badly in the real world. For that reason,
we are also going to dig deep into every service, and also consider the
availability from the client endpoint to ensure that we can confidently claim
that our approach will hit five nines or more from the infrastructure
standpoint.

Going multi-cloud is usually not helpful
----------------------------------------

There is quite a strong push and even consensus in the industry that utilizing
multiple public clouds is the way to go for high availability. That is somewhat
true if you have a stateless service which can easily be replicated into
multiple clouds, like web page serving. However, most APIs that exist on the
internet require shared state. You need to be able to mutate the data, and you
often need to have some consistency guarantees when doing it. This means that
you will need to run a multi-cloud database solution - usually by yourself as
databases that are highly available enough do not usually get offered as a
global service. While those might look good on paper, the operational complexity
of such a solution usually means that you need a team of significant size to
manage it all, and even then the actual real world availability is very likely
to be less than five nines for the first five to ten years.

This complexity problem also applies to other parts of the solution. Achieving
five nines of availability in the real world is extremely rare and very few
companies are able to do it. When utilizing multiple public clouds, the
maintainers of the solution need to be intimately familiar with each of them.
They need to know the exact behaviour of the load balancers when replacing
nodes, they need to know all the pitfalls how an update might break things and
they need to stick to components that are available from all the cloud
providers, which usually means that they will need to self-manage a lot more
components that otherwise could've been gotten as maanged services.

And finally, even if you go multi cloud, there's still going to be shared
components. The first hop will always be somewhat shared. You can have DNS
servers from multiple providers for the same domain, but if any of your DNS
servers return incorrect info, you are likely to affect the availability of your
API immediately. If you build synchronization between the DNS servers, then you
are building something where there's a chance that incorrect info from one side
will affect the availability of the entire solution.

In short, just don't do it.

Multi-country service basics
----------------------------

The very first thing to realize is that it's not possible to reach five nines of
availability utilizing a single data center. There are enough data center
failure modes in the world, even with data centers which have independent power
and network lines coming from both sides the building, that you can't reach five
nines of availability with a single data center. In general, you can't even
reach four nines. So multiple data centers (multiple buildings which are at
least kilometers apart) are a must.

What many people don't realize that it isn't possible to consistently reach more
than four nines of availability with a single country. Even if you have multiple
data centers, if you are running a global service and not a service for the
customers of that single country, you are going to have a hard time reaching
five nines of availability. None of the public cloud providers offer it for any
service – and they are the experts in real world availability. All of them cap
the availability of a single country to 99.99%.

That means that from the get go you need to design the solution so that it runs
in multiple countries (usually called regions). This means that there has to be
some way to distribute the requests into multiple independent services in
different countries, and to monitor the health of those services so that if one
country goes down, it will no longer get routed any requests.

Picking a database
------------------

This brings a pretty big problem in terms of mutable state. Single country
mutable state can often be done with synchronous replication as the latency
between different data centers can be 1-2 milliseconds. Mutable state between
countries often needs to be asynchronous, as latencies between countries range
from 20-40 milliseconds if close by, or to 100-200 milliseconds if actually
going all over the globe. For the worst cases, write latencies of 800
milliseconds might happen.

There are very few databases which offer 99.999% availability as a service.
Let's go over a few of them.

**Amazon DynamoDB:** Fully managed NoSQL database that offers a clean 99.999% SLA.
The replication mode is always asynchronous, with later changes overwriting
earlier changes if they happen within the replication window. This means it is
eventually consistent, but not strongly consistent, with regards to
multi-country operations. Single country writes are strongly consistent and
transactions are available, so if the keys you write to do not rapidly change
regions, DynamoDB can be practically strongly consistent in usage.

**Amazon Keyspaces:** Fully managed Cassandra database that offers a 99.999%
SLA. It is a NoSQL database that offers an SQL API. It offers multiple
consistency levels, including strong consistency. The details here are quite
complex, so outside of the scope of this article. If you know Cassandra, you
know it already.

**Google Cloud Spanner:** Fully managed SQL database that also offers a 99.999%
SLA. Being an SQL database and it offers standard ACID guarantees. This means
that writes need a quorum of replicas to be written to before the write is
acknowledged in order to keep consistency. Reads are fast, but there's no simple
way to get eventual consistency.

**Azure CosmosDB:** Fully managed database that offers a 99.999% SLA. It is a
NoSQL database that also offers an SQL API. It offers multiple consistency
levels, including strong consistency. The details here are quite complex, so
outside of the scope of this article.

**CockroachDB:** A SQL database that offers a 99.999% SLA. It can be self-hosted
but there's also a managed version available. It offers strong consistency and
transactions, but on a global table the writes may have up to 800 ms of latency
depending on the exact configuration. Everything is configured per table, so
it's possible to combine both local and global tables in the same database.
Eventual consistency is not offered easily, so it needs to be implemented
manually if needed.

There's a few more, and a lot of databases that offer almost five nines of
reliability. Also, many pieces of software are built to be able to run in a
setup which offers five nines of availability, but they don't offer it as a
service.

Whatever you pick is up to you, and could be a full article in itself, so this
list is just to help you get started.

Overview of the availability components
---------------------------------------

Let's assume that you have a multi country setup implemented for your API
service, with separate endpoints for each country, backed by some global
database. In order for the customers to reach those API endpoints, there's
several steps they need to go through, and several things which can go wrong.
We'll go over the things in order to build a path.

**Domain:** The first thing, which isn't usually considered, is the domain. And
I don't mean DNS, I mean the actual domain name you've bought from a registrar.
In terms of availability, this usually doesn't need to be considered, because of
the .com TLD is down, the world has bigger problems. If you are extremely
serious about this, you can buy a domain from multiple registrars with different
TLSs, but if you are offering a service behind an API, nobody wants to implement
code that tries different domains in order to find one that works.

The more important issue here is that if the domain is not renewed, or if it is
transferred to someone else, that might bring your entire service down and make
it impossible for you to restore the service. To prevent this from happening, my
recommendation is that you buy the domain from the same cloud hosting provider
you are using so that it gets paid on the same bill and is not easily missed.

**DNS:** The next thing is the DNS name your API service is advertised as.
Usually it's something like `api.yourcompany.com`. This is where the all the
clients will try to access your service, and that's what determines if your
service is up or down. Obviously if your DNS servers are down, or they don't
return the correct IP addresses for your service, then your service is down.

DNS is easily distributed, hence there are a lot of providers that offer DNS
services above the five nines barrier. Some even offer a 100% SLA, even though
that is obviously unattainable, but they are willing to pay the fines for the
miniscule amount of downtime they might have. Some offer a 99.9999% (six nines)
SLA, which is more believable.

You can also easily use multiple different providers for the same domain, so if
any of them are answering, then your domain should be up. However, this isn't as
useful as it sounds, because you usually don't have just a few static IP
addresses that will all work always. Instead you will have IP addresses that you
need to do health monitoring on and return only the valid IP addresses to
minimize the effects on the clients. In this case, having multiple providers do
health checks, and possibly do them in an inconsistent way, means that the
clients get different answers depending on which server they end up asking. This
adds complexity to the whole setup and might actually make it less reliable as a
whole. I would suggest sticking to one reliable DNS provider as that should
easily pass the five nines barrier.

**Global traffic manager:** This is not a service you necessarily might have.
I'm talking about services like AWS Global Accelerator, Cloudflare Load
Balancer, or Azure Front Door. These usually provide static anycast IP addresses
that will route the traffic to the closest data center. They also do health
checks on the data centers and route the traffic only to the healthy ones.
Sometimes this is also coupled with performance benefits, where the traffic is
routed from the edge into internal cloud provider networks, possibly providing a
faster route to your servers. Here's a test page for [AWS Global
Accelerator](https://speedtest.globalaccelerator.aws/#/) to measure the speed
benefit.

In general, these are very useful services to have, but the problem is that they
rarely offer full five nines of availability. Even though it's a distributed
anycast service, there's still enough state that the service can go down. And
the IP addresses might have routing issues.

**Load balancer:** This is the regional endpoint that you'll set up in each
region that will then route to your actual servers handling the API. Or maybe
it's an API gateway to begin with. In any case, the availability of a single
region isn't terribly critical. Even if the regional availability would be just
99%, if there are three independent regions, the availability of the whole
system could be 99.9999% (six nines), assuming everything else works perfectly.
Normally you'd aim for 99.95% or 99.9% for each of the regions and you'd utilize
at least three different regions.

I'll stop here, as all the rest is up to your specific architecture. The main
focus here is getting the path from the client to a specific region to be as
reliable as possible.

Is using DNS failover and health checks enough?
-----------------------------------------------

Mostly every guide on achieving 99.999% will just assume that the DNS is 100%
available, and that it has health checks that will automatically route traffic
to healthy regions. For browsers, this is often enough as a whole. Browsers are
very well behaved network clients which will try all the IP addresses returned
from DNS in order, and if one of them works, they will stick to it. Browsers
also quite eagerly try to refresh addresses from DNS, so they don't want to use
stale responses.

However, if you are building an API service, your clients are mostly not
browsers. Instead they are clients written in various programming languages, or
command line software. These clients will often just pick a random IP address
from the DNS response and use that. Then they will send a request there, often
without any kind of retry, because `POST` requests cannot be trivially retried.
That means that if you have any IP addresses you resolve from DNS that are not
healthy, it's likely your clients will observe an impact.

This is a problem because the DNS propagation time isn't zero, even if you set
the DNS TTL to zero or a low number. In general, when you make changes to DNS,
it might take a few minutes for the changes to propagate and to be seen by all
clients. Many components on the way might cache DNS records longer than the TTL,
even though that's not strictly allowed. If you rely only on DNS health checks,
you might have a few minutes of downtime for a portion of your client base every
time you have regional outage.

Now, if your target is 99.999%, then that means you can have 5.26 minutes of
downtime per year, or 26.3 seconds per month. That means that even a single
regional downtime might go over these limits. On paper, you might be 100%
available, but from the viewpoint of the clients, you might not be.

That means that simply relying on DNS health checks is not enough.

Is using a global traffic manager enough?
-----------------------------------------

The next go-to solution is to use some global traffic manager, like AWS Global
Accelerator. This solves the DNS propagation issue, as the change is on the
global traffic manager side in a failover and not the DNS. The DNS is simply
static. These usually also support rather fast health checks, and very fast
switchover times so the downtime can be minimized.

But, like mentioned earlier, these services are not 100% available. Usually they
don't advertise five nines of availability, and even when they do, it seems it's
more that they can pay the fines if necessary. There is a reason why the SLA is
so low, so it is best to not just assume they'll always be up. The services are
based on a few anycast IP addresses, and rely on those being routed correctly on
the internet. But the internet experiences relatively frequent routing issues do
to rogue BGP announcements, DDoS attacks, etc. This means that the IP addresses
might not be reachable from some parts of the world, or that the traffic might
be routed through a congested link, causing high latency.

So while these improve the quality of the service over the DNS failover, they
fall short of the five nines of availability.

Solution: Why not both?
------------------------

So this is the actual meat of the article. The solution is to use both DNS
failover and a global traffic manager. I'm going to be describing the setup as
it concretely can be done on AWS, but the same principles apply to other cloud
providers.

Let's assume you have three regions, US East, EU West and Asia Pacific. You have
an Application Load Balancer in each of the regions that is the REST service you
wish to provide.

You set up a Global Accelerator which routes traffic to the three regional
endpoints. You set up health checks on the Global Accelerator to check the
health of the regional endpoints. A sidenote: the Global Accelerator doesn't
actually do any health checks in this case, it simply relies on the reported
state of the Application Load Balancers. This global accelerator will have two
static IP addresses.

In addition to this, you set up a Network Load Balancer in each of the regions
that routes to the Application Load Balancer. Each of these Network Load
Balancers has two static IP addresses. This is an alternate route to your
Application Load Balancers that bypasses the Global Accelerator.

Then, in Route53, you set up a DNS name, `ga.api.yourcompany.com`, that points
to the two static IP addresses of the Global Accelerator. These addresses should
have Route53 health checks enabled with the 10 second frequency. This means that
if either of the anycast addresses goes down due to a routing issue, the DNS
will only return the working address.

Next, you set up a DNS name, `nlb.api.yourcompany.com`, that points directly to
the six static IP addresses of the Network Load Balancers in the three regions.
These addresses should also have Route53 health checks enabled with the 10
second frequency, so only working addresses are returned. If you want to be
fancy here, you can also set these up as latency based routing rules, but unless
your service will work significantly poorly if being routed to a far away
region, the added complexity may cause more issues than it solves.

Finally, you set up a DNS name, `api.yourcompany.com`, that has two `ALIAS`
records in a failover configuration. The primary record points to the
`ga.api.yourcompany.com` and the secondary record points to the
`nlb.api.yourcompany.com`. This will automatically mean that if the all of the
Global Accelerator health checks fail, the DNS will return addresses from the
Network Load Balancers.

This means that for the majority of your operations, all the clients will be
routed through Global Accelerator, which means they will get the benefit of
faster failovers and internal network routing. However, if the Global
Accelerator service is ever down, either due to a routing issue, configuration
issue or a service issue, the setup will automatically fall back to DNS based
failover directly to the Network Load Balancers. The fall back to DNS will
obviously be subject to the DNS propagation delays, but it will still likely be
fast enough to stay within the five nines of availability boundary.

**That means that this setup will not only give you the best achievable
availability using Global Accelerator, but will survive a Global Accelerator
outage without any manual intervention.**

Cost estimation
---------------

The cost to run such a setup is quite manageable. Route53 hosted zone costs
$0.50 per month. Each health check costs $0.50 per month, so $4.00 per month in
our case with eight health checks. A single Global Accelerator costs $0.025 per
hour, which leads to a monthly cost of $18.26. A single Network Load Balancer
costs $0.0225 per hour, which leads to a monthly cost of $16.39, so 3 load
balancers cost $49.17. So, in total, the monthly cost of the setup is $71.67 per
month.

Obviously this doesn't count the cost of your actual API service, and there's
varying traffic costs. But this gives a ballpark figure that setting up a highly
available API service on AWS does not need to break the bank, even if you are
aiming for five nines of availability.

Closing words
-------------

We live in amazing times where we can build services that are available to the
entire world with a few clicks of a button and a few lines of code. Achieving
five nines of availability with traditional data centers would've been a
multi-million dollar project, but now it's within reach of a single person.

Too bad it's mainly used for cat pictures.
