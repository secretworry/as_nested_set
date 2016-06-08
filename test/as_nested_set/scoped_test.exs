defmodule AsNestedSet.ScopedTest do
  use ExUnit.Case
  doctest AsNestedSet.Scoped
  defmodule Sample do
    use AsNestedSet.Scoped, scope: [:scope_field]
    defstruct scope_field: nil, non_scope_field: nil
  end

  test "should export same_scope/2" do
    Sample.same_scope?(%Sample{}, %Sample{})
  end

  test "same_scope/2 should return true for models with the same scope field value" do
    assert Sample.same_scope?(%Sample{scope_field: "same", non_scope_field: "diff0"}, %Sample{scope_field: "same", non_scope_field: "diff1"})
  end

  test "same_scope/2 should return false for models with different scope field value" do
    assert !Sample.same_scope?(%Sample{scope_field: "diff0"}, %Sample{scope_field: "diff1"})
  end
end
