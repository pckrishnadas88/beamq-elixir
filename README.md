# Beamq

A fault-tolerant, high-throughput distributed job processing engine built in Elixir. 

Beamq is designed to explore core distributed systems concepts on the BEAM, moving beyond basic CRUD background jobs into deep OTP architectures. It strictly adheres to the "Let it crash" philosophy while guaranteeing zero silent job loss.

## 🚀 Key Engineering Features (Phase 2)

*   **Immutable Job Ledger:** Jobs are never prematurely popped from the queue. They transition through an explicit state machine (`ready` → `running` → `completed` | `failed`) within an ACID-like local ETS table.
*   **Crash Isolation & Monitoring:** Workers do not run as raw `spawn` processes. They are managed by a `Task.Supervisor` and monitored via `async_nolink`. If a worker violently crashes (e.g., bad data or network timeout), the Scheduler traps the `:DOWN` exit signal and safely transitions the job to a `failed` state.
*   **High-Throughput Dispatch:** Eliminates polling bottlenecks. The Scheduler uses a recursive dispatch loop to instantly drain the queue when jobs are present, only falling back to a 1000ms sleep tick when the queue is completely empty.

## 🏗️ System Architecture

The application is rooted in a `One_for_one` supervision tree:

```text
Beamq.Supervisor
 ├── Beamq.Store            (GenServer managing ETS State Ledger)
 ├── Beamq.WorkerSupervisor (Dynamic Task.Supervisor isolating worker faults)
 └── Beamq.Scheduler        (GenServer coordinating dispatch and process monitoring)

```

**Job Lifecycle:**
`Producer` → `Store (ETS)` → `Scheduler` (Requests Worker) → `Task.Supervisor` (Spawns Worker) → `Worker` (Executes & Returns) → `Scheduler` (Updates Store)

## ⚙️ Running the System

```bash
mix deps.get
mix compile
iex -S mix

```

## 🧪 Interactive Examples

### 1. The Happy Path (High Throughput)

Insert multiple jobs. The Scheduler will recursively dispatch them instantly in parallel, bypassing the 1-second tick loop.

```elixir
iex> Beamq.Store.add("email_1")
iex> Beamq.Store.add("email_2")
iex> Beamq.Store.add("email_3")

# ✅ Executing job: "email_1"
# ✅ Executing job: "email_2"
# ✅ Executing job: "email_3"
# 19:06:30.170 [info] Job 1 completed with result: "email_1"

```

### 2. The Chaos Test (Fault Tolerance)

Insert a poison-pill payload designed to force a runtime exception.

```elixir
iex> Beamq.Store.add("crash")

# 🧨 Worker is about to crash violently!
# ** (RuntimeError) Boom! Network timeout or bad data.
# 19:06:31.000 [error] Job 4 crashed! Reason: {%RuntimeError{...}}

```

Notice that the BEAM isolates the crash. The Scheduler survives, catches the `:DOWN` signal, and safely marks the job as failed in the ETS ledger without losing the data.

```elixir
iex> :ets.tab2list(:beamq_jobs)
# [
#   {1, %{id: 1, payload: "email_1", status: :completed, attempts: 1}},
#   {4, %{id: 4, payload: "crash", status: :failed, attempts: 1}}
# ]

```