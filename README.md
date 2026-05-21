# Beamq

A minimal distributed job queue built in Elixir using OTP principles.

## Overview

Beamq is a learning project inspired by systems like Oban and RabbitMQ.
It demonstrates core distributed systems concepts using OTP:

- Job scheduling
- Worker isolation
- Fault-tolerant supervision
- ETS-based storage

## Architecture

Producer → Store (ETS) → Scheduler → Worker processes


## Components

- **Store**: Holds jobs in ETS
- **Scheduler**: Picks jobs every second
- **Worker**: Executes jobs in isolated processes
- **Supervisor**: Restarts system components on failure

## Run

```bash
mix deps.get
mix compile
iex -S mix
```

## Example

```bash
Beamq.Store.add(%{task: "hello world"})
```