defmodule AsNestedSet.Factory do
  use ExMachina.Ecto, repo: AsNestedSet.TestRepo

  use ExMachina

  def factory(:taxon) do
    %AsNestedSet.Taxon{name: sequence(:name, &"name-#{&1}")}
  end
end
