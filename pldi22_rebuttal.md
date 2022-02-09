We thank the reviewers for their valuable feedback. We address major
concerns first, followed by reviewer-specific comments.

Use of Synchronization
----------------------

While merges in Carmot use synchronization, it is only one aspect of
our overall approach. Our contribution is to show *how* to use
synchronization in a way that (a). Replicas are always available for
user actions, (b). No user action has to wait for a remote replica to
respond, and (c). Replicas eventually converge. There are several ways
one could use synchronization yet fail to achieve the aforementioned
objectives. For e.g:

1. Each user operation is synchronized: this leads to violation of
   properties (a) and (b).
2. Merges synchronize by ``stoping the world'' to pull the latest
   version from all the branches. This too violates properties (a) and
   (b) as no replica can progress when one replica is merging.
3. Merges are synchronized with each other; each merge is aware of,
   and has all the information from, the previous merges: this would
   linearize merges *in time*, but nonethless results in ill-formed
   histories that violate property (c). For e.g., in Fig.5(b) merges
   could be ordered linearly in time, yet result in divergence.

As summarized by Reviewer B, our key discovery is the well-formedness
condition that translates to LCA-based premises of Merge and FastFwd
rules. These conditions effectively ensure that LCAs in any history
DAG are organized as a lattice, which gives us the unique LCA property
(Lemma 3.4), and thereby convergence (Theorem 3.7). The reasoning
about LCAs is critical to convergence, and cannot be done away with.
We use synchronization to perform the the checks on LCAs, which inturn
guarantees convergence. Otherwise synchronization in itself is not
very useful.

Conversely, synchronization is not necessarily an antithesis to
practical adoption. Google docs, for instance, famously relies on a
centralized OT server to coordinate all its edits.

Comparison with MRDTs and CRDTs
--------------------------------

Despite their best efforts to ensure convergence, Kaki et al's MRDT
merges [13] nonetheless result in divergence. For e.g., our
`Set.merge` in Sec.1 is same as Kaki et al's set merge, yet it results
in divergence as shown in Figs.4(b) and 5(b). The existence of these
counterexamples is in fact why they were not able to prove MRDT
convergence (source: personal communication). While convergence is
only a small aspect of full-functional correctness, getting it right
is not easy, even for the experts
([Here](https://twitter.com/martinkl/status/1327025979454263297?lang=en)
is a recent example from CRDTs. Another example is the queue
persistent data structure from [Farinier et
al](https://hal.inria.fr/hal-01099136v1/document), which turned out to
admit the multiple LCA anomaly and (thereby) divergence). We hope
our formal guarantees help the community advance the discussion on
RDTs past convergence.

Evaluation
------------

We have chosen to do one in-depth case study instead of experimenting
with a collection of RDTs as it lets us examine the tradeoffs more
closely. All the MRDT benchmarks from Kaki et al continue to work on
Carmot with no increase in latency and diff size measurements. Carmot
is in fact a fork of Quark -- the system from Kaki et al. Carmot
extends Quark with an more efficient network and storage layer (due to
Scylla), and a runtime component that is activated only during a merge
(happens in a background thread). **It is important to note that
Carmot does not introduce any additional overhead on a user action to
guarantee convergence**. When a user submits an action, it is
immediately executed and committed to the local version. Thus, insofar
as user interaction is concerned, Carmot is qualitatively no different
from any other CRDT system. Unfortunately, we couldn't find a
standardized CRDT system (akin to Quark for MRDTs) for us to do
comparisons against.

It is possible to give theoretical upper bound on staleness in Carmot.
We have proved (elsewhere) that a ring topology guarantees the
uniqueness of LCAs by construction without a need for global
synchronization. If replicas are organized as a ring, the maximum
staleness is the sum of latencies on the circumference of the ring.
Hence if we have replicas distributed across US-east and US-west, it
is reasonable to expect staleness to be in the order of 100ms. As it
stands now, our implementation simply reflects our formal model, which
includes no such optimizations. 


Lastly, we'd like to point out that this work introduces staleness as
a novel tradeoff against convergence. While trading off staleness may
not be an optimal choice for every application, the fact that there
exists such a tradeoff is, in our opinion, noteworthy. And if an
application has to chose between latency and staleness, staleness is
arguably the less disruptive choice.


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
  asymptotically sub-optimal, relational decomposition leads to simple
  yet useful merges for a range of data structures. The problem,
  however, is that [13] lacks either a system or a proof that
  guarantees the convergence of resultant MRDTs. We show that
  divergence is possible despite a sensible merge semantics, and close
  this gap.

* Git acknowledges the possibility of multiple LCAs in its
  [documentation](https://git-scm.com/docs/merge-strategies). The
  default merge strategy of Git is `recursive`, which recursively
  merges LCAs if there are multiple of them. This however merely a
  heuristic. We have found a pathological case where such recursive
  merging could become a problem (Full example with illustrations
  included in the appendix).
  [Others](http://r6.ca/blog/20110416T204742Z.html) have also found
  cases where Git merge is inconsistent. We haven't contacted the Git
  maintainers yet. 


Reviewer C
----------

* We hope the reviewer's concerns on staleness and performance are
  addressed by our note on Evaluation above.

Reviewer D
-----------

* Every client forks off a branch which is effectively a replica, so
  there are multiple replicas per machine. With 30 clients, there are
  30 branches with 30 replicas distributed across 3 machines.

* Inclusion of a runtime imposes no additional overhead on the latency
  of individual operations. Given that Carmot uses synchronization for
  merges, and the overhead of synchronization increases at least
  linearly with the number of replicas, one would expect the latency
  of each operation to grow at least linearly *if* the runtime
  interferes with the normal execution. Fig.10 categorically
  demonstrates that this is not the case. Hence the conclusion that our
  approach imposes no additional cost on latency and availability (our
  latency measurement accounts for availability too as it measures the
  time from the operation is submitted to the time a result is
  received. If the availability of the system goes down, then
  operations have to wait longer to find a replica, increasing their
  overall latency. Fig.10 shows this is not the case with Carmot.)

* Being based on MRDTs, our approach *is* indeed comparable to CRDTs.
  The absence of synchronization in CRDTs is a result of careful
  engineering by domain experts [20, 25, 26, 11]. In the absence of
  such expertise, the only alternative available to an application
  developer is to synchronize every operation. Our approach presents a
  third alternative -- a compromise where developer need not
  synchronize every operation, yet obtain convergence. 

* Our claim in contribution bullet #2 pertains to the formalization of
  the abstract machine and the theorems we prove on it. Mechanization
  in Ivy, similar to mechanization in Coq, is intended to convey the
  confidence in the soundness of our meta-theory. Our Ivy development
  very closely resembles our formalization in Sections 3 and 4
  (including the theorems). Lemmas 3.4 to 3.8 have been proved in Ivy.
  In addition, we also proved that the concrete semantics of Sec. 4
  refine the abstract semantics of Sec. 3. While Sledgehammer extends
  an interactive proof assistant (Isabelle/HOL) with SMT support, our
  mechanized verification in Ivy is wholly SMT-driven; there is no
  interactive theorem proving involved (we have separately done manual
  proofs however). We shall include more details on Ivy formalization,
  and the comparison with Sledgehammer approach in the final version.

* We hope your questions on merge synchronization are answered by the
  note on Evaluation above.
