defmodule AsNestedSet.Factory do
  use ExMachina.Ecto, repo: AsNestedSet.TestRepo

  def taxon_factory do
    %AsNestedSet.Taxon{name: sequence(:name, &"name-#{&1}")}
  end
end
