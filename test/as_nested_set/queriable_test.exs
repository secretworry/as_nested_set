defmodule AsNestedSet.QueriableTest do
  use AsNestedSet.EctoCase

  import AsNestedSet.Factory
  import AsNestedSet.Matcher
  alias AsNestedSet.Taxon

  @doc """
  Create a nested set tree
  +--------------------+
  |      +-----------+ |
  | +---+| +-------+ | |
  |0|1 2||3|4 5|6 7|8|9|
  +--------------------+
  """
  def create_tree(taxonomy_id) do
    n0 = insert(:taxon, name: "n0", lft: 0, rgt: 9, taxonomy_id: taxonomy_id)
    n00 = insert(:taxon, name: "n00", lft: 1, rgt: 2, parent_id: n0.id, taxonomy_id: taxonomy_id)
    n01 = insert(:taxon, name: "n01", lft: 3, rgt: 8, parent_id: n0.id, taxonomy_id: taxonomy_id)
    n010 = insert(:taxon, name: "n010", lft: 4, rgt: 5, parent_id: n01.id, taxonomy_id: taxonomy_id)
    n011 = insert(:taxon, name: "n011", lft: 6, rgt: 7, parent_id: n01.id, taxonomy_id: taxonomy_id)
    {n0, [
      {n00, []},
      {n01, [
        {n010, []},
        {n011, []}
      ]}
    ]}
  end

  test "right_most/1 works find" do
    create_tree(1)
    assert Taxon.right_most(%{taxonomy_id: 1}) == 9
  end

  test "children/1 should get all children in the right sequence" do
    {root, [{no_child, []}, {with_child, _}]} = create_tree(1)
    assert match(Taxon.children(root),[
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1},
    ])
    assert match(Taxon.children(no_child), [])
  end

  test "leaves/1 should return all leaves" do
    create_tree(1)
    assert match(Taxon.leaves(%{taxonomy_id: 1}), [
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n010", lft: 4, rgt: 5, taxonomy_id: 1},
      %{name: "n011", lft: 6, rgt: 7, taxonomy_id: 1},
    ])
  end

  test "descendants/1 should return all decendants" do
    {root, _} = create_tree(1)
    assert match(Taxon.descendants(root), [
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1},
      %{name: "n010", lft: 4, rgt: 5, taxonomy_id: 1},
      %{name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}
    ])
  end

  test "descendants/1 returns [] for node without child" do
    {_, [{no_child, []}|_]} = create_tree(1)
    assert Taxon.descendants(no_child) == []
  end

  test "root/1 returns nil for emtpy tree" do
    assert Taxon.root(%{taxonomy_id: 1}) == nil
  end

  test "root/1 returns the root of the tree" do
    create_tree(1)
    assert match(Taxon.root(%{taxonomy_id: 1}),
      %{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}
    )
  end
end
