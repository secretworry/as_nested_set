defmodule AsNestedSet.EctoCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AsNestedSet.TestRepo)
  end
end
