# `defimpl for: Any` introduces spurious compile-connected dependencies

## Project structure

```
lib/
├── presentable.ex          # Protocol with @fallback_to_any true
├── presentable/
│   ├── any.ex              # defimpl for Any
│   ├── cat.ex              # defimpl for Models.Cat
│   └── dog.ex              # defimpl for Models.Dog
├── models/
│   ├── cat.ex              # Simple struct
│   └── dog.ex              # Simple struct
└── protocol_fallback_bug.ex
```

## Reproducing

```bash
cd ~/workspace/protocol_fallback_bug
mix compile
mix xref graph --label compile-connected --fail-above 0
```

Outputs 4 compile-connected edges and fails. Every `defimpl` gets a compile-connected dependency to the protocol, and the `Any` impl and protocol form a compile cycle.

## Key finding during investigation

The trigger is actually the existence of `defimpl for: Any` — not `@fallback_to_any true` itself. I tested all four combinations:

| `@fallback_to_any true` | `defimpl for: Any` | Compile-connected deps |
|---|---|---|
| No | No | 0 |
| Yes | No | 0 |
| No | Yes | 4 |
| Yes | Yes | 4 |

So the issue is that when a protocol has an implementation for `Any`, the protocol module gains a compile dependency on `any.ex`, and then every other implementation that has a compile dependency on the protocol becomes compile-connected transitively. This means changing any implementation (or the protocol itself) cascades into recompilation of all other implementations. In a real project with 23+ implementations, this completely defeats protocol-based decoupling.
