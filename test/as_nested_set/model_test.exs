defmodule AsNestedSetTest.ModelTest do
  use ExUnit.Case
  doctest AsNestedSet.Model
  defmodule Sample do
    use AsNestedSet.Model
    defstruct left: "left", right: "right", parent_id: "parent_id"
  end

  defmodule Redefined do
    use AsNestedSet.Model
    @parent_id_column :pid
    @left_column :lft
    @right_column :rgt
    defstruct lft: "left", rgt: "right", pid: "parent_id"
  end

  test "should define left/1 method" do
    sample = %Sample{}
    assert Sample.left(sample) == sample.left
    redefined = %Redefined{}
    assert Redefined.left(redefined) == redefined.lft
  end

  test "should define right/1 method" do
    sample = %Sample{}
    assert Sample.right(sample) == sample.right
    redefined = %Redefined{}
    assert Redefined.right(redefined) == redefined.rgt
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
end
