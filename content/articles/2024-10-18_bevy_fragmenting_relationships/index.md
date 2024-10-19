+++
title = "Reconsidering fragmenting relationships in Bevy"
draft = true

[taxonomies]
categories = ["fun"]
+++
I want to give my own opinion about implementing fragmenting relationships in Bevy. I am not convinced that they are the only, or the best, solution to the whole relationships issue.

## What's an archetypal ECS?

In a basic C++ game engine, each game object is their own allocation. The engine might have objects that do everything based on some flags, or might have different classes for different types of objects using inheritance etc. A lot of games right now do not use an ECS, and that's fine – the games perform very well. But this places a heavy burden on the system allocator to perform well, and it's not really friendly to the cache as each object is littered randomly in memory.

An ECS is a system where each game object (entity) is composed of individual component objects. These component objects are all exactly the same class, so the same size with just different data, so they can be stored efficiently in an array. The game logic is then implemented as systems which apply to all objects which have certain components. This is very cache friendly, as the operations linearly traverse through the relevant components and handle all of them in a single batch. So, strictly speaking, we have one array per component type, and then we need a way to map from entities to all these component arrays.

An archetypal ECS takes this a step further. It automatically defines an archetype for each combination of components that an entity might have. This has two benefits. First of all, it means that an entity's components can be looked up by just archetype id and then index within that archetype. Second, it means that it's easy to find entities which have a certain set of components, as all you have to do is to find all archetypes which contain that set of components and then iterate through those. So this means that in an allocation sense, each archetype will have separate array or arrays. The entity could be stored as one tuple with all the components in a row, as they all have the same set of components, but more commonly each component is still stored in a separate array. This is because not all traversals need all components, so the cache will end up only caching the relevant components when they are being traversed.

The archetypal ECS is a very good performance boost for games which handle a lot of entities. It is very cache friendly as components are read in bulk by the systems that operate on a single set of components at a time. It is also a kind of an indexing system for which components are present as the archetypes act as indexes at the same time. As long as there isn't a huge number of different archetypes, it's quite optimal – and quite popular in the games these days.

## Where does the archetypal ECS fall short?

Entities in a game often have relationships, meaning that they point to other entities. A typical use of this is a parent-child relationship, where a child entity has a parent entity. This is often used with a transform component, where the child entity's position and transformation is relative to the parent entity's position and transformation. In an ECS, this is represented by components that contain entity ids. When traversing this entity id reference, you first need to look up where the entity is from an entity id table which tells the archetype and the index, and then look up the components from the archetype data arrays.

Generally this isn't a problem and performs reasonably well. But when the main traversal for a system, such as with the transform component, is based on this system it means that the components that are read are no longer linearly laid out in memory, but instead possibly accessed in a random fashion. This means constant cache misses and can tank the performance of the whole engine.

## FLECS solution: fragmenting relationships

The FLECS ECS library has a solution for this. It's called fragmenting relationships. The idea is that instead of components only being able to be in an archetype, also relationships with an entity can be in the archetype. So, to simplify, it means that each parent gets its own archetype. This means all the children for that parent are in a neat array, so when traversing the tree of entities based on that relationship, it will again be cache friendly as the components are laid out linearly in memory.

It's not without its faults though. If the amount of children per parent is low, it means there's not much linearity benefit to this approach as the entities end up dispersed in memory anyway. Also, FLECS allows fragmenting relationships along multiple components, which means that if there are two orthogonal relationships, then having an architype for each combination of these orthogonal relationships will lead to a huge number of archetypes. And a huge number of archetypes makes it hard again to find all the entities that have a certain set of components, which can be mitigated with different sort of indexes on archetypes.

Which is all to say that in the pathological case, the fragmenting relationships approach degrades to just a normal game engine with separate allocations for each object – which is still good! Like said, most engines do not really use an ECS and they perform well. But it doesn't have the ECS performance benefits of cache friendly traversal.

## Alternative solution for Bevy: sorting!

The performance problem with the parent-child relationship is that the components are not linearly laid out in memory, leading to cache misses and random traversal. But what if we would lay out the components so that they would actually be in traversal order?

The order of entities in an archetype is essentially random, as it's based when the entity has been inserted in that archetype. The same entity will always change positions in the archetype arrays when moving between different archetypes. So the order of entities in an archetype is not really useful for anything. So what we could do is to sort the entities for an archetype based on the parent. This way, when traversing the parent-child relationship, all the children of a single parent would be laid out linearly in memory. When sorted, it would give the same benefits as the fragmenting relationships approach, but inside a single archetype where all the arrays are continguous. This means that there wouldn't be one memory allocated array per component per parent, but instead one memory allocated array per component, which is even more optimal for this case.

Changing the order of entities in the archetype is easy, as there are already operations that swap the location of an entity inside an archetype. But it's harder to keep the array sorted when new entities are added or removed. If the rate of churn is low, it might be enough to just periodically sort the arrays. The unsorted elements will all be at the end anyway, so it's likely that cache performance will be adequate even if the arrays are not perfectly sorted.

## Evolution: incremental sorting!

We can sort the whole array at once. If there isn't a ton of entities, it's probably not going to be visible in the performance metrics if we do it every once in a while. But still, it's a big bang memory operation at once, so there are likely to be games where that's not feasible.

What we can probably do is to just sort the array incrementally, some number of elements at a time per frame. It doesn't matter if the end result isn't perfect if some elements get removed for example, as the cache misses will be minimal. They will anyway be handled properly on the next pass. I feel like this `O(n log n)` sorting in the background is probably something that's sustainable for a lot of games and optimizes the traversal more than what is the cost of the constant sorting.

We might be able to do even better! The basic idea is to sort the archetype per the parent element, which means we declare the parent element to be the primary traversal operation. That's not going to be the case for all queries and not all the games. So, what if we could automatically sort the entities based on a query? Meaning that we'd automatically swap the elements to be in the order which the query visits them. Then we wouldn't have to know about the traversal order in advance, we would just need to flag a query as being the main query to optimize for. An archetype can only be sorted in one order anyway (unless we go for really advanced stuff like z-order sorting), so we can't do it for every query.

But, we were supposed to do incremental sorting. So, what if we flag the query to sort the elements as they are traversed, but count the number of swaps actually made, and stop when that count exceeds a number? This way each frame would sort the archetypes a bit more in the traversal order of the query, but not all the way. So, probably cache performance would end rapidly improving even after big changes, but there wouldn't be a big pause as an entire archetype is sorted.

## The nitty gritty details

This is just an idea, and there's no implementation yet. There's a ton of difficulties to be solved to make something efficient. For example, trying to sort things strictly in traversal order performs really badly if one element is added to the beginning of the sorted order – we need to swap every element after that to get them to the right place, even though they are almost perfectly sorted already. So, most likely we will need some cache-oblivious algorithms to make sure the tables for each archetype can be mostly sorted while not causing significant memory churn. Possibly we might also need to change the table storage for archetypes to some more advanced cache-oblivious data structure.

However, there's tons of different approaches here that can be tried - and most of it will likely be easily togglable on and off without interfering too much with the existing code. So, if the approach seems to be logically sound, then all this work can progress incrementally and it will either pay off in the end, or it won't – that still remains to be seen.


