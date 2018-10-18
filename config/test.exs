use Mix.Config

config :as_nested_set, AsNestedSet.TestRepo,
  hostname: "localhost",
  database: "as_nested_set_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
