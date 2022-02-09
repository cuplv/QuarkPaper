We thank the reviewers for their valuable feedback. We address major
concerns first, followed by reviewer-specific comments.

Use of Synchronization
----------------------

Merges in Carmot use synchronization. However, synchronization does
not trivially guarantee convergence. Our contribution is to show
*how* to use synchronization in a way that (a). Replicas are always
available for user actions, (b). No user action has to wait for a
remote replica to respond, and (c). Replicas eventually converge. To
demonstrate the subtlety in our use of synchronization, consider the
following trivial synchronizations:

1. Each operation is synchronized -- the system would violate
   aforementioned properties (a) and (b).
2. Merges ``stop the world'' to pull the latest version from all the
   branches -- violates properties (a) and (b) as no replica can
   progress when one replica is merging.
3. Only merges are synchronized; each merge is aware of, and has all
   the information from, the previous merges -- this would linearize
   merges *in time*, but nonethless results in ill-formed histories
   that violate property (c). Fig e.g., in Fig.5(b) merges could be
   ordered linearly in time, yet result in divergence.

Our key discovery is the LCA-based premise of Merge and FastFwd
rules that effectively ensure that LCAs in any history are organized
as a lattice. This inturn is based on our observation that multiple
LCAs inevitably lead to divergence in general case. We use
synchronization to enable the checks on LCAs and enforce the lattice
property (Corollary 3.6). Otherwise Synchronization in itself doesn't
constitute the solution.

Comparison with MRDTs and CRDTs
--------------------------------

Despite their best efforts to ensure convergence, Kaki et al's MRDT
merges [13] nonetheless result in divergence. For e.g., our
`Set.merge` in Sec.1 is same as Kaki et al's set merge, yet it results
in divergence as shown in Figs.4(b) and 5(b). The existence of these
counterexamples is in fact why they were not able to prove MRDT
convergence (source: personal communication). While convergence is
only a small aspect of full-functional correctness, ensuring it in the
context of CRDTs and MRDTs remains extremely challenging even for the
experts
([here](https://twitter.com/martinkl/status/1327025979454263297?lang=en)
is a recent example from CRDTs).  We hope our formal guarantees of
convergence would make RDTs accessible to non-experts.

Evaluation
------------

We have chosen to do one in-depth case study instead of experimenting
with a collection of RDTs as it lets us examine the tradeoffs more
closely. All the MRDT benchmarks from Kaki et al continue to work on
Carmot with no increase in latency and diff size measurements. Carmot
is in fact a fork of Quark -- the system from Kaki et al. Carmot
extends Quark with an more efficient network and storage layer (due to
Scylla), and a runtime component that is activated only during a merge
(happens in a background thread). **There is no additional overhead
associated with a user action**. When a user submits an action, it is
immediately executed and committed to the local version. Thus, insofar
as user interaction is concerned, Carmot is qualitatively no different
from any other CRDT system. Unfortunately, we couldn't find a
standardized CRDT system (akin to Quark for MRDTs) for us to do
comparisons against.

It is possible to give theoretical upper bound on staleness in
Carmot. Ring topology guarantees the uniqueness of LCAs (Lemma 3.4) by
construction (without a need for synchronization). If replicas are
organized as a ring, the maximum staleness is the sum of latencies on
the circumference of the ring. Hence if we have replicas distributed
across US-east and US-west, it is reasonable to expect staleness to be
in the order of 100ms. As it stands now, our implementation simply
reflects our formal model, which includes no such optimizations.
Lastly, we'd like to note that mere presence of synchronization doesn't
necessarily lead to unacceptable performance. Google docs, for
instance, relies on a centralized OT server to coordinate all its
edits and yet has acceptable performance.

Reviewer A
----------

* The concrete semantics of Sec.4 *refines* the abstract semantics of
  Sec. 3. The proof we did in Ivy is in fact a refinement proof (can be
  found in `quarkRefineImplement.ivy` in the supplementary material). We
  are incorrect in stating that all properties have been re-proved for
  the concrete semantics. The fact is that the properties follow
  because Sec.4 semantics is a refinement of Sec.3 semantics. We
  apologize for the confusion.

* For comments on Related Work and Evaluation, please see above.


Reviewer B
----------

* Useful merge functions exist for more complicated data structures.
  In [13] Kaki et al provide a constructive definition of well-formed
  merges with help of *relational decomposition*. Albeit
  computationally inefficient, relational decomposition leads to
  simple yet useful merges for a range of data structures. The
  problem, however, is that [13] lacks either a system or a proof that
  guarantees the convergence of resultant MRDTs. As demonstrated
  above, divergence is possible despite a sensible merge semantics.
  Carmot closes this gap.


Reviewer C
----------

* We hope your concerns on staleness and performance are addressed by
  our note on Evaluation above.

Reviewer D
-----------

* Every client forks off a branch which is effectively a replica, so
  there are multiple replicas per machine. With 30 clients, there are
  30 branches with 30 replicas distributed across 3 machines.

* Inclusion of a runtime imposes no additional overhead on the latency
  of individual operations. Given that Carmot runtime uses
  synchronization for merges, and the overhead of synchronization
  increases at least linearly with the number of replicas, one would
  expect the latency of each operation to grow at least linearly if it
  is affected by the presence of runtime. However, as Fig.10
  demonstrates, that's not the case. Hence the conclusion that our
  approach imposes no additional cost on latency and availability (our
  latency measurement accounts for availability too as it measures the
  time from the operation is submitted to the time a result is
  received. If the availability of the system goes down, then
  operations have to wait longer to find a replica, increasing their
  overall latency. Fig.10 shows this is not the case with Carmot.)

* We hope your other comments on performance are addressed by our note
  on Evaluation above.
