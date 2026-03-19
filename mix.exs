defmodule ProtocolFallbackBug.MixProject do
  use Mix.Project

  def project do
    [
      app: :protocol_fallback_bug,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
