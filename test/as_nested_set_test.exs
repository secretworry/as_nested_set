defmodule AsNestedSetTest do

  use ExUnit.Case

  defmodule Sample do
    use AsNestedSet
    defstruct id: "id", lft: "left", rgt: "right", parent_id: "parent_id"
  end

  defmodule Redefined do
    use AsNestedSet.Model
    @node_id_column :node_id
    @parent_id_column :pid
    @left_column :left
    @right_column :right
    defstruct node_id: "node_id", left: "left", right: "right", pid: "parent_id"
  end
  
  defmodule Undefined do
    defstruct id: "id"
  end

  @fields ~w{node_id left right parent_id}a

  test "should define __as_nested_set_get_field__(model, field)" do
    sample = %Sample{}
    redefined = %Redefined{}
    assert Sample.__as_nested_set_get_field__(sample, :node_id) == sample.id
    assert Redefined.__as_nested_set_get_field__(redefined, :node_id) == redefined.node_id

    assert Sample.__as_nested_set_get_field__(sample, :left) == sample.lft
    assert Redefined.__as_nested_set_get_field__(redefined, :left) == redefined.left

    assert Sample.__as_nested_set_get_field__(sample, :right) == sample.rgt
    assert Redefined.__as_nested_set_get_field__(redefined, :right) == redefined.right

    assert Sample.__as_nested_set_get_field__(sample, :parent_id) == sample.parent_id
    assert Redefined.__as_nested_set_get_field__(redefined, :parent_id) == redefined.pid
  end

  test "should define __as_nested_set_set_field__(model, field, value)" do
    sample = %Sample{}
    redefined = %Redefined{}
    sample = @fields |> Enum.reduce(sample, fn field, sample ->
      Sample.__as_nested_set_set_field__(sample, field, "test_value")
    end)
    assert %Sample{id: "test_value", lft: "test_value", rgt: "test_value", parent_id: "test_value"} == sample

    redefined = @fields |> Enum.reduce(redefined, fn field, redefined ->
      Redefined.__as_nested_set_set_field__(redefined, field, "test_value")
    end)
    assert %Redefined{node_id: "test_value", left: "test_value", right: "test_value", pid: "test_value"} == redefined
  end

  test "should define __as_nested_set_fields__" do
    assert %{left: :lft, node_id: :id, parent_id: :parent_id, right: :rgt} == Sample.__as_nested_set_fields__
    assert %{left: :left, node_id: :node_id, parent_id: :pid, right: :right} == Redefined.__as_nested_set_fields__
  end

  test "should define child?(model)" do
    assert Sample.child?(%Sample{parent_id: "parent_id"})
    refute Sample.child?(%Sample{parent_id: nil})

    assert Redefined.child?(%Redefined{pid: "parent_id"})
    refute Redefined.child?(%Redefined{pid: nil})
  end
  
  describe "AsNestedSet.defined?/1" do
    test "should return true for a struct defined AsNestedSet" do
      assert AsNestedSet.defined?(Sample)
      assert AsNestedSet.defined?(%Sample{})
    end
    test "should return false for a module defined AsNestedSet" do
      refute AsNestedSet.defined?(Undefined)
      refute AsNestedSet.defined?(%Undefined{})
    end
  end
end
