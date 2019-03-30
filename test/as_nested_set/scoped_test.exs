defmodule AsNestedSet.ScopedTest do
  use ExUnit.Case
  doctest AsNestedSet.Scoped

  defmodule Sample do
    use AsNestedSet.Scoped, scope: [:scope_field]
    defstruct scope_field: nil, non_scope_field: nil
  end

  test "should export same_scope/2" do
    AsNestedSet.Scoped.same_scope?(%Sample{}, %Sample{})
  end

  test "same_scope/2 should return true for models with the same scope field value" do
    assert AsNestedSet.Scoped.same_scope?(%Sample{scope_field: "same", non_scope_field: "diff0"}, %Sample{scope_field: "same", non_scope_field: "diff1"})
  end

  test "same_scope/2 should return false for models with different scope field value" do
    assert !AsNestedSet.Scoped.same_scope?(%Sample{scope_field: "diff0"}, %Sample{scope_field: "diff1"})
  end

  describe "scope/1" do
    test "should return default scope" do
      assert AsNestedSet.Scoped.scope(Sample) == [:scope_field]
    end

    test "should return scope for given instance" do
      assert AsNestedSet.Scoped.scope(%Sample{scope_field: "value"}) == %{scope_field: "value"}
    end
  end

  describe "assign_scope_from/2" do
    test "should assign scope from source to target" do
      source_scope = %{scope_field: "source"}
      source = struct(Sample, source_scope)
      target = %Sample{scope_field: "target"} |> AsNestedSet.Scoped.assign_scope_from(source)
      assert AsNestedSet.Scoped.scope(target) == source_scope
    end
  end
end
