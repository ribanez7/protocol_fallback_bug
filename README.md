# `defimpl for: Any` introduces spurious compile-connected dependencies

**Elixir:** 1.19.5 (compiled with Erlang/OTP 28)
**Erlang/OTP:** 28.4.1

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
mix compile
mix xref graph --label compile-connected --fail-above 0
```

### Output

```
lib/presentable.ex
└── lib/presentable/any.ex (compile)
** (Mix) Too many references (found: 1, permitted: 0)
```

The protocol definition (`presentable.ex`) has a compile dependency on its
`Any` implementation (`any.ex`). This is inverted; the protocol should not
depend on any of its implementations at compile time.

## Expected behavior

Zero compile-connected dependencies. Protocol implementations should only have
a runtime or exports dependency on the protocol definition, never the reverse.

## Why this matters

The compile dependency from the protocol to `any.ex` means:

1. Any change to `any.ex` forces `presentable.ex` to recompile.
2. Since all implementations depend on the protocol (via exports), they
   transitively recompile too.
3. In a real project with 23+ implementations, a single change to the `Any`
   fallback cascades into recompilation of every implementation file.

This defeats the purpose of protocols as a compile-time decoupling mechanism.

## Key finding

The trigger is the existence of `defimpl for: Any`, not `@fallback_to_any true`
itself. Tested all four combinations:

| `@fallback_to_any true` | `defimpl for: Any` | Compile-connected deps |
|---|---|---|
| No | No | 0 |
| Yes | No | 0 |
| No | Yes | 1 |
| Yes | Yes | 1 |

## Note on Elixir 1.18.x

On Elixir 1.18.3 (Erlang/OTP 27.3), the scope of this problem was larger.
Every `defimpl` file gained a compile-connected dependency to the protocol
(4 edges in this reproduction, not just 1), and all implementations formed a
compile cycle with the protocol through the `Any` implementation:

```
lib/presentable/any.ex
└── lib/presentable.ex (compile)
    └── lib/presentable/any.ex (compile)
lib/presentable/cat.ex
└── lib/presentable.ex (compile)
lib/presentable/dog.ex
└── lib/presentable.ex (compile)
```

It appears that 1.19.x partially fixed this; the implementations no longer
have direct compile deps to the protocol, but the inverted compile dependency
from the protocol to `any.ex` remains.
