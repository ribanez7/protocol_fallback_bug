defmodule ProtocolFallbackBugTest do
  use ExUnit.Case
  doctest ProtocolFallbackBug

  test "greets the world" do
    assert ProtocolFallbackBug.hello() == :world
  end
end
