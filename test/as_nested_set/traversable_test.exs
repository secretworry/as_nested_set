defmodule AsNestedSet.TraversableTest do

  use AsNestedSet.EctoCase
  import AsNestedSet.Factory

  import AsNestedSet.Traversable

  alias AsNestedSet.TestRepo, as: Repo
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

  test "traverse in the right order" do
    create_tree(1)
    {_, acc} = traverse(Taxon, %{taxonomy_id: 1}, [], fn node, acc ->
      {node, [node.name | acc]}
    end, fn node, acc ->
      {node, [node.name | acc]}
    end) |> execute

    assert ["n0", "n00", "n00", "n01", "n010", "n010", "n011", "n011", "n01", "n0"]
           == (acc |> Enum.reverse)
  end

  test "traverse forest in the right order" do
    create_forest(1)
    {_, acc} = traverse(Taxon, %{taxonomy_id: 1}, [], fn node, acc ->
      {node, [node.name | acc]}
    end, fn node, acc ->
      {node, [node.name | acc]}
    end) |> execute

    assert ["n0", "n0", "n1", "n1"] == (acc |> Enum.reverse)
  end

  test "traverse a subtree with right order" do
    {_, [_, {n01, _}]} = create_tree(1)

    {_, acc} = traverse(n01, [], fn node, acc ->
      {node, [node.name | acc]}
    end, fn node, acc ->
      {node, [node.name | acc]}
    end) |> execute

    assert ["n01", "n010", "n010", "n011", "n011", "n01"] == (acc |> Enum.reverse)
  end

  test "traverse should return node and context" do
    {root, _} = create_tree(1)
    assert_raise ArgumentError, ~r/Expect :pre to return {AsNestedSet.t, context} but got/, fn->
      traverse(root, [], fn node, _acc ->
        node
      end, fn node, _acc ->
        {node, []}
      end ) |> execute
    end
    assert_raise ArgumentError, ~r/Expect :post to return {AsNestedSet.t, context} but got/, fn->
      traverse(root, [], fn node, _acc ->
        {node, []}
      end, fn node, _acc ->
        node
      end ) |> execute
    end
  end

  test "traverse with 3 arguments post_fun should get children as the second argument" do
    {root, _} = create_tree(1)
    {_, acc} = traverse(root, [], fn node, acc -> {node, acc} end, fn node, children, acc ->
      {node, [{node.name, children |> Enum.map(fn x -> x.name end)} | acc] }
    end) |> execute
    assert acc == [
      {"n0", ["n00", "n01"]},
      {"n01", ["n010", "n011"]},
      {"n011", []},
      {"n010", []},
      {"n00", []}
    ]
  end
end
