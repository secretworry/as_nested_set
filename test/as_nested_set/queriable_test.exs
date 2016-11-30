defmodule AsNestedSet.QueriableTest do
  use AsNestedSet.EctoCase

  import AsNestedSet.Factory
  import AsNestedSet.Matcher
  alias AsNestedSet.Taxon

  alias AsNestedSet.TestRepo, as: Repo

  import AsNestedSet.Queriable


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

  def create_forest(taxonomy_id) do
    n0 = insert(:taxon, name: "n0", lft: 0, rgt: 1, taxonomy_id: taxonomy_id)
    n1 = insert(:taxon, name: "n1", lft: 2, rgt: 3, taxonomy_id: taxonomy_id)
    [
      {n0, []},
      {n1, []}
    ]
  end
  
  def execute(executable) do
    AsNestedSet.execute(executable, Repo)
  end

  test "right_most/2 works find" do
    create_tree(1)
    assert right_most(Taxon, %{taxonomy_id: 1}) |> execute() == 9
  end

  test "children/1 should get all children in the right sequence" do
    {root, [{no_child, []}, _]} = create_tree(1)
    assert match(children(root) |> execute(),[
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1},
    ])
    assert match(children(no_child) |> execute(), [])
  end

  test "leaves/2 should return all leaves" do
    create_tree(1)
    assert match(leaves(Taxon, %{taxonomy_id: 1}) |> execute(), [
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n010", lft: 4, rgt: 5, taxonomy_id: 1},
      %{name: "n011", lft: 6, rgt: 7, taxonomy_id: 1},
    ])
  end

  test "descendants/1 should return all decendants" do
    {root, _} = create_tree(1)
    assert match(descendants(root) |> execute(), [
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1},
      %{name: "n010", lft: 4, rgt: 5, taxonomy_id: 1},
      %{name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}
    ])
  end

  test "descendants/1 returns [] for node without child" do
    {_, [{no_child, []}|_]} = create_tree(1)
    assert descendants(no_child) |> execute() == []
  end

  test "root/2 returns nil for emtpy tree" do
    assert root(Taxon, %{taxonomy_id: 1}) |> execute() == nil
  end

  test "root/2 returns the root of the tree" do
    create_tree(1)
    assert match(root(Taxon, %{taxonomy_id: 1}) |> execute(),
      %{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}
    )
  end

  test "roots/2 returns the roots of the forest" do
    create_forest(1)
    assert match(roots(Taxon, %{taxonomy_id: 1}) |> execute(), [
      %{name: "n0", lft: 0, rgt: 1, taxonomy_id: 1},
      %{name: "n1", lft: 2, rgt: 3, taxonomy_id: 1}
    ])
  end

  test "self_and_descendants/1 should returns self and all descendants" do
    {_, [_, {target, _}|_]} = create_tree(1)
    assert match(self_and_descendants(target) |> execute(), [
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1},
      %{name: "n010", lft: 4, rgt: 5, taxonomy_id: 1},
      %{name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}
    ])
  end

  test "ancestors/1 should return all its ancestors" do
    {_, [_, {_, [{target, []}|_]}|_]} = create_tree(1)
    assert match(ancestors(target) |> execute(), [
      %{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1}
    ])
  end

  test "self_and_siblings/1 should return self and all its sliblings" do
    {_, [{target, _}|_]} = create_tree(1)
    assert match(self_and_siblings(target) |> execute(), [
      %{name: "n00", lft: 1, rgt: 2, taxonomy_id: 1},
      %{name: "n01", lft: 3, rgt: 8, taxonomy_id: 1}
    ])
  end

end
