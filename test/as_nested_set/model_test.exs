defmodule AsNestedSetTest.ModelTest do
  use ExUnit.Case
  doctest AsNestedSet.Model
  defmodule Sample do
    use AsNestedSet.Model
    defstruct lft: "left", rgt: "right", parent_id: "parent_id"
  end

  defmodule Redefined do
    use AsNestedSet.Model
    @parent_id_column :pid
    @left_column :left
    @right_column :right
    defstruct left: "left", right: "right", pid: "parent_id"
  end

  test "should define left/1 method" do
    sample = %Sample{}
    assert Sample.left(sample) == sample.lft
    redefined = %Redefined{}
    assert Redefined.left(redefined) == redefined.left
  end

  test "should define right/1 method" do
    sample = %Sample{}
    assert Sample.right(sample) == sample.rgt
    redefined = %Redefined{}
    assert Redefined.right(redefined) == redefined.right
  end

  test "should define parent_id/1 method" do
    sample = %Sample{}
    assert Sample.parent_id(sample) == sample.parent_id
    redefined = %Redefined{}
    assert Redefined.parent_id(redefined) == redefined.pid
  end

  test "should define child?/1 method" do
    sample = %Sample{}
    assert Sample.child?(sample)
    redefined = %Redefined{}
    assert Redefined.child?(redefined)
  end

  test "should define root?/1 method" do
    sample = %Sample{parent_id: nil}
    assert Sample.root?(sample)
    redefined = %Redefined{pid: nil}
    assert Redefined.root?(redefined)
  end

  test "should define left_column/0 method" do
    assert Sample.left_column == :lft
    assert Redefined.left_column == :left
  end

  test "should define right_column/0 method"  do
    assert Sample.right_column == :rgt
    assert Redefined.right_column == :right
  end

  test "should define parent_id_column/0 method" do
    assert Sample.parent_id_column == :parent_id
    assert Redefined.parent_id_column == :pid
  end
end
