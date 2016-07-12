defmodule AsNestedSet.ModifiableTest do

  use AsNestedSet.EctoCase

  import AsNestedSet.Factory
  import AsNestedSet.Matcher
  alias AsNestedSet.Taxon
  alias AsNestedSet.TestRepo, as: Repo

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

  test "create/3 should return {:err, :not_the_same_scope} for creating node from another scope" do
    node = insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert Taxon.create(%Taxon{taxonomy_id: 1}, node , :child) |> Taxon.execute(Repo) == {:err, :not_the_same_scope}
  end

  test "create/3 should return {:err, :target_is_required} for creating without passing a target" do
    insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert Taxon.create(%Taxon{taxonomy_id: 1}, :child) |> Taxon.execute(Repo) == {:err, :target_is_required}
  end

  test "create/3 should create left node" do
    {_, [{target, _}|_]} = create_tree(1)

    %Taxon{name: "left", taxonomy_id: 1} |> Taxon.create(target, :left) |> Taxon.execute(Repo)

    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "n0", lft: 0, rgt: 11, taxonomy_id: 1}, [
        {%{ name: "left", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "n00", lft: 3, rgt: 4, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 5, rgt: 10, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 6, rgt: 7, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 8, rgt: 9, taxonomy_id: 1}, []}
        ]}
      ]}
    )
  end

  test "create/3 should create right node" do
    {_, [{target, _}|_]} = create_tree(1)
    %Taxon{name: "right", taxonomy_id: 1} |> Taxon.create(target, :right) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "n0", lft: 0, rgt: 11, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "right", lft: 3, rgt: 4, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 5, rgt: 10, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 6, rgt: 7, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 8, rgt: 9, taxonomy_id: 1}, []}
        ]}
      ]}
    )
  end

  test "create/3 should create child node" do
    {_, [{target, _}|_]} = create_tree(1)
    %Taxon{name: "child", taxonomy_id: 1} |> Taxon.create(target, :child) |> Taxon.execute(Repo)

    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "n0", lft: 0, rgt: 11, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 4, taxonomy_id: 1}, [
          {%{ name: "child", lft: 2, rgt: 3, taxonomy_id: 1}, []}
        ]},
        {%{ name: "n01", lft: 5, rgt: 10, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 6, rgt: 7, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 8, rgt: 9, taxonomy_id: 1}, []}
        ]}
      ]}
    )
  end

  test "create/2 should create root node for empty tree" do
    %Taxon{name: "root", taxonomy_id: 1} |> Taxon.create(:root) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "root", lft: 0, rgt: 1, taxonomy_id: 1}, []}
    )
  end

  test "create/2 should create root node" do
    create_tree(1)
    %Taxon{name: "root", taxonomy_id: 1} |> Taxon.create(:root) |> Taxon.execute(Repo)
    assert match(Taxon.dump(%{taxonomy_id: 1}) |> Taxon.execute(Repo), [
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 3, rgt: 8, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 4, rgt: 5, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}, []}
        ]}
      ]},
      {%{name: "root", lft: 10, rgt: 11, taxonomy_id: 1}, []}
    ])
  end

  test "create/2 should create parent node" do
    {_, [{target, _}|_]} = create_tree(1)
    %Taxon{name: "parent", taxonomy_id: 1} |> Taxon.create(target, :parent) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo), {
      %{name: "n0", lft: 0, rgt: 11, taxonomy_id: 1}, [
        {%{name: "parent", lft: 1, rgt: 4, taxonomy_id: 1}, [
          {%{ name: "n00", lft: 2, rgt: 3, taxonomy_id: 1}, []},
        ]},
        {%{ name: "n01", lft: 5, rgt: 10, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 6, rgt: 7, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 8, rgt: 9, taxonomy_id: 1}, []}
        ]}
      ]
    })
  end

  test "create/3 should not affect other tree" do
    create_tree(1)
    create_tree(2)
    %Taxon{name: "root", taxonomy_id: 1} |> Taxon.create(:root) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 2}) |> Taxon.execute(Repo),
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 2}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 2}, []},
        {%{ name: "n01", lft: 3, rgt: 8, taxonomy_id: 2}, [
          {%{ name: "n010", lft: 4, rgt: 5, taxonomy_id: 2}, []},
          {%{ name: "n011", lft: 6, rgt: 7, taxonomy_id: 2}, []}
        ]}
      ]}
    )
  end

  test "delete/1 should delete a node and all its descendants" do
    {_, [_,{target, _}]} = create_tree(1)
    Taxon.delete(target) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "n0", lft: 0, rgt: 3, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "create/3 should create consecutive children" do
    root = %Taxon{name: "root", taxonomy_id: 1} |> Taxon.create(:root) |> Taxon.execute(Repo)
    %Taxon{name: "child0", taxonomy_id: 1} |> Taxon.create(root, :child) |> Taxon.execute(Repo)
    %Taxon{name: "child1", taxonomy_id: 1} |> Taxon.create(root, :child) |> Taxon.execute(Repo)
    assert match(Taxon.dump_one(%{taxonomy_id: 1}) |> Taxon.execute(Repo),
      {%{name: "root", lft: 0, rgt: 5, taxonomy_id: 1}, [
        {%{name: "child0", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{name: "child1", lft: 3, rgt: 4, taxonomy_id: 1}, []}
      ]}
    )
  end
end
