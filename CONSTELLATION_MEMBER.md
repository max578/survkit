# Orchestra membership — survkit

> **This project (survkit) is a MEMBER of the Orchestra** (one coordination
> structure; reconciled 2026-06-03). The leader-node is **ORCHESTRA_dev**
> (governance, roster, contracts, TACI, publication); the technical inference hub
> is **flexyBayes** (the dependency-DAG sink). This file is survkit's back-pointer
> to that charter and a map of my siblings.

- **My role:** the **time-to-event toolkit** — a registry-dispatched façade over
  the established R survival stack (Cox / KM / Weibull-AFT / Fine-Gray
  competing-risks / Andersen-Gill recurrent / frailty), normalised to one result
  shape with a small-sample (events-per-variable) honesty gate. The frequentist
  half of the survival paradigm-split (Bayesian survival → flexyBayes).
- **Contracts I own / honour:** I **emit `survkit_manifest`** (a parameter-draw
  ensemble, shaped to but not importing PESTO's **C2** `pesto_ensemble_manifest` —
  a composition-layer adapter lifts it). I consume no manifest.
- **My edge:** producer — survkit (frequentist survival) triangulates with
  flexyBayes/koine (Bayesian survival) and feeds decideR (timing decisions). My
  `frailty` random effect is the survival analogue of the MET random effect,
  tying me to the MET spine. Acyclic on the producing side.
- **What binds me (charter invariants):** *single-responsibility* (time-to-event
  only); *extensible registry* (`survkit_register()` adds an estimator without
  touching the API); *soft abstention* (the EPV power gate warns +
  `verdict = "underpowered"`); *leader-directed adoption*.
- **Governance:** survkit is a **Max-owned personal package** (MIT-track);
  the AAGI-AUS canon does not apply. Development version (0.0.0.9000).

## My siblings (the full roster — so I am informed about the others)

| Member | Role | Class |
|---|---|---|
| flexyBayes | inference hub (owns C1/C4/C5/C7) | open (AAGI-gated) |
| PESTO | calibration + manifest source (C2) | open |
| kernR | validation + TACI/ACI engine | open |
| proxymix | KL-optimal proxy compression; the `proxymix_map` optimisation engine | open |
| gretaR | engine — torch MCMC | open |
| koine | synthesis — fourth opinion | open |
| terroir | data collector (C6) | open (MIT) |
| kalmix | state-space / change-point / ACI | open (MIT) |
| masque | data sovereignty (clones) | open |
| apsimR | external engine — APSIM Next Gen | open (MIT-src) |
| bourse | grounded market-data connector (trading arm) | open |
| survkit | **time-to-event toolkit (this package)** | open |
| janusplot | asymmetric GAM association matrices (diagnostic-viz) | open |
| gpfield | change-of-support spatial GP; emits `orchestra_manifest` | open (MIT) |
| decideR | decision layer (loss-optimal closer) | open |
| grainPlan | grain decision-orchestration (on decideR) | open (MIT) |
| optimix | optimisation meta-layer; emits `orchestra_manifest` | open (MIT) |
| flexyBayesOrchestra | composition layer (surrogates, koine backend) | open |

Planned: genoR. **Canonical charter:** `ORCHESTRA_dev/ORCHESTRA.md` (mirrored in
the MaxAIbase brain, open tier). **Contract + dependency DAG:**
`ORCHESTRA_dev/integration/orchestra_manifest.R`.
