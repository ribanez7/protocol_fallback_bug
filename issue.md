### Environment

* Elixir & Erlang/OTP versions (elixir --version): Elixir 1.19.5 (compiled with Erlang/OTP 28), Erlang/OTP 28.4.1
* Operating system: any

### Current behavior

`defimpl for: Any` creates an inverted compile dependency from the protocol definition to the `Any` implementation, forming a compile cycle. This causes changes to `any.ex` to force recompilation of the protocol, and transitively all other implementations.

Protocol:

```elixir
defprotocol Presentable do
  @fallback_to_any true

  @spec to_type(t()) :: map() | nil
  def to_type(entity)
end
```

Struct:

```elixir
defmodule Models.Cat do
  defstruct [:name]
end
```

Implementation:

```elixir
defimpl Presentable, for: Models.Cat do
  def to_type(%Models.Cat{name: name}), do: %{kind: "cat", name: name}
end
```

Any implementation:

```elixir
defimpl Presentable, for: Any do
  def to_type(_entity), do: nil
end
```

Running `mix xref graph --label compile-connected --fail-above 0` shows:

```
lib/presentable.ex
└── lib/presentable/any.ex (compile)
** (Mix) Too many references (found: 1, permitted: 0)
```

The trigger is the existence of `defimpl for: Any`, not `@fallback_to_any true` itself. Removing the `Any` implementation while keeping `@fallback_to_any true` results in zero compile-connected dependencies.

You can check the repo created to reproduce the issue here: https://github.com/ribanez7/protocol_fallback_bug

**Note:** On Elixir 1.18.3 (Erlang/OTP 27.3) the scope was larger; every `defimpl` file gained a compile-connected dependency to the protocol (4 edges instead of 1). It appears 1.19.x partially fixed this but the inverted dependency from the protocol to `any.ex` remains.

### Expected behavior

`defimpl for: Any` should not add a compile dependency from the protocol to the implementation. I expect to run `mix xref graph --label compile-connected --fail-above 0` and have zero compile-connected dependencies.
