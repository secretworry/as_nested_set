defmodule AsNestedSet.Mixfile do
  use Mix.Project

  def project do
    [app: :as_nested_set,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: app_list(Mix.env)]
  end

  def app_list(:test), do: app_list ++ [:ecto, :postgrex, :ex_machina]
  def app_list(_), do: app_list
  def app_list, do: [:logger]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 2.0.0-beta", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:test]},
      {:ex_machina, "~> 1.0.0-beta.1", github: "thoughtbot/ex_machina", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths ++ ["test/support"]
  defp elixirc_paths(_), do: elixirc_paths
  defp elixirc_paths, do: ["lib"]
end
