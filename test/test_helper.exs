Mix.Task.run "ecto.drop", ["quiet", "-r", "AsNestedSet.TestRepo"]
Mix.Task.run "ecto.create", ["quiet", "-r", "AsNestedSet.TestRepo"]
Mix.Task.run "ecto.migrate", ["-r", "AsNestedSet.TestRepo"]

AsNestedSet.TestRepo.start_link
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(AsNestedSet.TestRepo, :manual)
