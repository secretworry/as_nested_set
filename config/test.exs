use Mix.Config

config :as_nested_set, AsNestedSet.TestRepo,
  hostname: "localhost",
  database: "as_nested_set_test",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
