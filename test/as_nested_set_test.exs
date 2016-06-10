defmodule AsNestedSetTest do
  use AsNestedSet.EctoCase

  import AsNestedSet.Factory
  alias AsNestedSet.Taxon

  @doc """
  Create a nested set tree
  +------------+
  | +---++---+ |
  |0|1 2||3 4|5|
  +------------+
  """
  def create_tree(taxonomy_id) do
    n0 = insert(:taxon, name: "n0", lft: 0, rgt: 5, taxonomy_id: taxonomy_id)
    n00 = insert(:taxon, name: "n00", lft: 1, rgt: 2, parent_id: n0.id, taxonomy_id: taxonomy_id)
    n01 = insert(:taxon, name: "n01", lft: 3, rgt: 4, parent_id: n0.id, taxonomy_id: taxonomy_id)
    {n0, [
      {n00, []},
      {n01, []}
    ]}
  end

  def match([source|source_tail], [target|target_tail]) do
    match(source, target) and match(source_tail, target_tail)
  end

  def match({source, source_children}, {target, target_children}) do
    match(source, target) and match(source_children, target_children)
  end

  def match([], []) do
    true
  end

  def match(source, target) when is_map(source) and is_map(target) do
    name = source.name
    lft = source.lft
    rgt = source.rgt
    taxonomy_id = source.taxonomy_id
    %{:name => ^name, :lft => ^lft, :rgt => ^rgt, :taxonomy_id => ^taxonomy_id} = target
    true
  end

  test "create/3 should return {:err, :not_the_same_scope} for creating node from another scope" do
    node = insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert Taxon.create(node, %Taxon{taxonomy_id: 1}, :child) == {:err, :not_the_same_scope}
  end

  test "create/3 should return {:err, :target_is_required} for creating without passing a target" do
    insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert Taxon.create(%Taxon{taxonomy_id: 1}, :child) == {:err, :target_is_required}
  end

  test "create/3 should create left node" do
    {root, [{target, _}|_]} = create_tree(1)

    Taxon.create(target, %Taxon{name: "left", taxonomy_id: 1}, :left)

    assert match(Taxon.dump(%{taxonomy_id: 1}), [
      {%{name: "n0", lft: 0, rgt: 7, taxonomy_id: 1}, [
        {%{ name: "left", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "n00", lft: 3, rgt: 4, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 5, rgt: 6, taxonomy_id: 1}, []}
      ]}
    ])
  end

  test "create/3 should create right node" do
    {root, [{target, _}|_]} = create_tree(1)
    Taxon.create(target, %Taxon{name: "right", taxonomy_id: 1}, :right)
    assert match(Taxon.dump(%{taxonomy_id: 1}), [
      {%{name: "n0", lft: 0, rgt: 7, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "right", lft: 3, rgt: 4, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 5, rgt: 6, taxonomy_id: 1}, []}
      ]}
    ])
  end

  test "create/3 should create child node" do
    {root, [{target, _}|_]} = create_tree(1)
    Taxon.create(target, %Taxon{name: "child", taxonomy_id: 1}, :child)

    assert match(Taxon.dump(%{taxonomy_id: 1}), [
      {%{name: "n0", lft: 0, rgt: 7, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 4, taxonomy_id: 1}, [
          {%{ name: "child", lft: 2, rgt: 3, taxonomy_id: 1}, []}
        ]},
        {%{ name: "n01", lft: 5, rgt: 6, taxonomy_id: 1}, []}
      ]}
    ])
  end

  test "create/3 should create root node for empty tree" do
    Taxon.create(%Taxon{name: "root", taxonomy_id: 1}, :root)
    assert match(Taxon.dump(%{taxonomy_id: 1}), [
      {%{name: "root", lft: 0, rgt: 1, taxonomy_id: 1}, []}
    ])
  end

  test "create/3 should create root node" do
    create_tree(1)
    Taxon.create(%Taxon{name: "root", taxonomy_id: 1}, :root)
    assert match(Taxon.dump(%{taxonomy_id: 1}), [
      {%{name: "root", lft: 0, rgt: 7, taxonomy_id: 1}, [
        {%{name: "n0", lft: 1, rgt: 6, taxonomy_id: 1}, [
          {%{ name: "n00", lft: 2, rgt: 3, taxonomy_id: 1}, []},
          {%{ name: "n01", lft: 4, rgt: 5, taxonomy_id: 1}, []},
        ]}
      ]}
    ])
  end
end
