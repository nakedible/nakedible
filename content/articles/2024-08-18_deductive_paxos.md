+++
title = "Understanding Paxos Consensus Algorithm: Deductive approach"
date = 2024-08-18
draft = true

[taxonomies]
categories = ["cloud"]
+++

Definitions
-----------

**Node:** A participant in the consensus process. A node must be able to communicate to other nodes and a node must have persistent (non-volatile) state. A node may crash at any time, as long as that does not mean that the persistent state is lost. If even a single node loses the persistent state permanently, the safety guarantees of the consensus protocol do not hold anymore. Different consensus protocols may separate the roles of nodes further to proposers, acceptors, learners, etc. but for simplicity I will just consider nodes that can fulfill all the roles.

**Network:** The way nodes can send messages to any other node, usually the internet. It is assumed that messages are sent asynchronously and may take arbitrarily long to get delivered, and that messages may be lost, reordered or duplicated. However, it is assumed that messages are delivered without corruption, or that corruption is detected and such messages are dropped.

**CAP theorem:** Also called Brewer's theorem, that states that any distributed data store can provide only two of the following three guarantees: consistency, availability and partition tolerance. These guarantees or properties are discussed separately.

**Quorum:** A minimum number of nodes that must be involved in a decision making process to reach consensus. If less than a quorum of non-failing nodes is available, a consensus cannot be reached and the availability is impacted.

**Consensus:** A chosen value among the nodes which is the result of the protocol.

Properties
----------

**Safety (Consistency):** Every attempt to reach consensus reaches the same result or an error. Error doesn't necessarily mean that a consensus wasn't formed, but it just means that there was some error that we did not learn that the consensus was reached, so we must try again. The result must be one of the values proposed for the consensus. This means that once a value has been chosen as the consensus, it must not change anymore. When consensus has not yet been reached, there may be multiple proposed values.

**Liveness (Availability):** If there is at least a quorum of non-failing nodes, they must eventually be able to reach a consensus. This is not strictly enough for the liveness property, but since it is impossible to achieve all three properties of the CAP theorem at the same time, we must downgrade this to eventual availability. This mean that every attempt to reach a consensus does not need to succeed, as there may be reasons to abort a consensus attempt in case of a conflict.  But if there is only one node proposing a value for consensus, the protocol should be able to reach a consensus without errors. That means that the only way the protocol cannot proceed when a quorum of nodes is available if there are synchronized conflicting writes from different nodes on each attempt. This means that a jitter of some sort should be employed to ensure that writes will not stay synchronized.

**Fault tolerance (Partition tolerance):** The consensus system continues to operate despite an arbitrary number of messages being dropped, delayed or repeated by the network between nodes. This is a necessary property in any networked system – regardless whether it is the internet, or simply multiple hard disks inside a single computer.

Deductions
----------

### Any two quorums must share at least one member

If two quorums of nodes can be formed which do not share even one member, then these quorums can decide on a different value, which violates the safety property. Hence, there must always be at least one member in common between any two quorums. If we are maximizing availability, then this means that a quorum can be any set of nodes which has more than half of the nodes. N/2 + 1.

### Consensus happens when all members of a quorum accepts a value

If only some members of a quorum have accepted a proposal when a consensus is declared, then another quorum of nodes might contain only nodes which have not accepted the proposal. Hence, in order for a consensus to be achieved, all members of a quorum need to accept the same proposal for a value.

### Nodes will not know immediately when a consensus is achieved

Consensus forms when a quorum of nodes accepts a proposal for a value. However, due to the asynchronous nature of the network, it is impossible for all the nodes to know at the same time when this happens. Consensus is reached at the exact moment when the last member of a quorum accepts a value, meaning that it stores the value in persistent storage. Since nodes may crash and messages may be lost, this doesn't mean that the specific consensus attempt does not result an error, but it means further attempts at the consensus need to return the same value for which consensus was reached.

### Each node must be able to propagate last proposed value

Since there might be only a single node in common between two quorums and since the nodes do not necessarily know if a quorum has been reached or not, this means that the single node must be able to report the last proposed value as that might be a value that forms a consensus. It is up to the protocol to ensure that if it is possible that the value has been part of a consensus that it will end up as the chosen value to preserve safety.

### Two consensus attempts must not finish in parallel

If two consensus attempts are able to proceed in parallel with a quorum of nodes, they could end up with different selected values at the final step as they do not have knowledge of the proposed value of the other attempt. This doesn't mean that any part of the algorithm must not proceed in parallel, but it means that proposal acceptance must not happen in mixed order between two consensus attempts.

### Newer consensus attempts must abort earlier attempts

If an in-progress consensus attempt would prevent future attempts at consensus, a node crashing or messages being lost would mean that the protocol would violate the liveness property. Unfortunately this also means that we might end up in a situation where every consensus attempt is aborted by a new attempt, which would prevent the protocol from reaching a consensus. Such issues must be prevented by ensuring that consensus attempts are not repeatedly aborted by other consensus attempts, usually through jitter in retries.

### Only the latest proposed value may form a consensus

Given that each node propagates the last proposed value and two quorums must share at least one member, that means that if there are multiple proposed values among a quorum of nodes, we know that only the latest proposed value may possibly form a consensus. If the earlier proposed values would have been a part of a consensus, then they would have been propagated to any future consensus attempts.

### The protocol must at minimum have two round-trips

Since we need to propagate the latest proposed value among a quorum of nodes, this means that we need to first obtain the latest proposed value from the nodes. After that we may attempt to accept the latest value as a consensus, or if there is no latest value at all, we may pick a value ourselves. But in order to reach consensus, we need to ensure that at least a quorum of nodes has accepted the value, which means that there's a second round-trip is necessary.

Deduced protocol
----------------

Nodes need to store persistently two things: value and number. We know we need to store the latest proposed value, which may or may not form a consensus. We also know we must abort earlier consensus attempts when a new consensus is attempted, so we need some number to order consensus attempts and to mark which attempts have been aborted.

We know we need at least two round-trips, so let's assume that is sufficient. Let's call the two requests as prepare and accept.

**Prepare:** The node must return the latest saved value for that node and the consensus attempt number, so we can find the latest proposed value. It must also abort any ongoing consensus attempts, so it should store a new number which corresponds to this consensus attempt. It should immediately return an error if an already aborted consensus attempt number is used.

**Accept:** The node simply stores the proposed value and proposal number and confirms that it has been stored. It must instead immediately report an error if the proposal number is for a proposal that has already been aborted.

**Protocol:**

1. Pick a new proposal number, larger than any number picked so far. A simple timestamp will do. If clocks are not reliable, then a simple counter can be used, if every node will return the latest counter value also on errors.
2. Send prepare messages to all the nodes containing the proposal number. A quorum of nodes is enough, but usually we don't know which nodes will answer, so to maximize availability, we send it to all.
3. If less than a quorum of nodes answer successfully, abort and restart. As an optimization, if any node answers with the error that this proposal number has already been aborted, then it's better to instantly restart.
4. Pick the value with the highest proposal number from all the answers, or if there are no values returned then generate any value. The generated value may be given as a proposed parameter to the protocol invocation at the start, or it may be generated on the fly.
5. Send accept messages to all the nodes containing the proposed value along with the proposal number. This will either confirm a previous possible consensus or form a new one.
6. If less than a quorum of nodes answer successfully, abort and restart. A consensus might've been formed, but we just didn't learn it, or a consensus might've not been formed because less than a quorum of nodes actually saved the value.
7. Return proposed value as the chosen consensus value. We know that this value will never change, so as an optimization we can broadcast it to where ever it is needed so that the consensus protocol doesn't need to be rerun.

That's it. That's all there is to have a working Paxos implementation. Everything else is then optimization.

Sample implementation in JavaScript, using 

```javascript
class Node {
  constructor() {
    this.n = 0;
    this.v = undefined;
  }

  async prepare(n) {
    if n <= this.n {
      throw new Error("restart");
    }
    const prev = this.n;
    this.n = n;
    return {
      v: this.v,
      n: prev,
    };
  }

  async accept(n, v) {
    if n < this.n {
      throw new Error("restart");
    }
    this.n = n;
    this.v = v;
  }
}

async function propose(proposed_value, nodes) {
  let quorum = (nodes.length / 2) + 1;
  // pick number
  const n = Date.now();
  // send prepare to all nodes
  const all_results = await Promise.allSettled(nodes.map(node => node.prepare(n)));
  // check that we got a quorum of successes
  const success_results = all_results.filter(r => r.status === "fulfilled");
  if success_results.length < quorum {
    throw new Error("restart");
  }
  // find latest value or if there is no value then use given value
  const sorted_results = success_results.filter(r => r.value.v != null).sort((a, b) => a.value.n - b.value.n);
  const v = sorted_results[0].value.v || proposed_value;
  // send accept to all nodes
  const all_results = await Promise.allSettled(nodes.map(node => node.accept(n, v)));
  // check that we got a quorum of successes
  const success_results = all_results.filter(r => r.status === "fulfilled");
  if success_results.length < quorum {
    throw new Error("restart");
  }
  // return chosen value
  return v;
}
```

Multi-Paxos
-----------

Paxos algorithm is used to decide a single consensus per instance. That means that once consensus has been reached, the value will never change. In the real world, this is rarely useful. Instead the need is often to either have consensus on sequential log of values, or a single value which can be changed by consensus.

Both of these are solved by Multi-Paxos. 

```
Condition expression: seq < :s
Update expression: SET seq = :s
Return values: ALL_NEW
Condition expression: seq <= :s
Update expression: SET seq = :s, val = :v
Return values: NONE
```
