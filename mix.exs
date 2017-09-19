defmodule ScpToAnywhere.Mixfile do
  use Mix.Project

  def project do
    [
      app: :scp_to_anywhere,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: {ScpToAnywhere, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.9.0"},
      {:distillery, "~> 1.4", runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
