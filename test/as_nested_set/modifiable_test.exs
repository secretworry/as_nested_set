defmodule AsNestedSet.ModifiableTest do

  use AsNestedSet.EctoCase

  import AsNestedSet.Factory, only: [insert: 2]
  import AsNestedSet.Matcher
  alias AsNestedSet.Taxon
  alias AsNestedSet.TestRepo, as: Repo

  import AsNestedSet.Modifiable
  import AsNestedSet.Queriable, only: [dump: 2, dump_one: 2]

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

  def execute(executable) do
    AsNestedSet.execute(executable, Repo)
  end

  test "create/3 should return {:error, :not_the_same_scope} for creating node from another scope" do
    node = insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert create(%Taxon{taxonomy_id: 1}, node , :child) |> execute == {:error, :not_the_same_scope}
  end

  test "create/3 should return {:error, :target_is_required} for creating without passing a target" do
    insert(:taxon, lft: 0, rgt: 1, taxonomy_id: 0)
    assert create(%Taxon{taxonomy_id: 1}, :child) |> execute == {:error, :target_is_required}
  end

  test "create/3 should create left node" do
    {_, [{target, _}|_]} = create_tree(1)

    %Taxon{name: "left", taxonomy_id: 1} |> create(target, :left) |> execute

    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
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
    %Taxon{name: "right", taxonomy_id: 1} |> create(target, :right) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
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
    %Taxon{name: "child", taxonomy_id: 1} |> create(target, :child) |> execute

    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
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
    %Taxon{name: "root", taxonomy_id: 1} |> create(:root) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "root", lft: 0, rgt: 1, taxonomy_id: 1}, []}
    )
  end

  test "create/2 should create root node" do
    create_tree(1)
    %Taxon{name: "root", taxonomy_id: 1} |> create(:root) |> execute
    assert match(dump(Taxon, %{taxonomy_id: 1}) |> execute, [
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
    %Taxon{name: "parent", taxonomy_id: 1} |> create(target, :parent) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute, {
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
    %Taxon{name: "root", taxonomy_id: 1} |> create(:root) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 2}) |> execute,
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
    delete(target) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 3, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "create/3 should create consecutive children" do
    root = %Taxon{name: "root", taxonomy_id: 1} |> create(:root) |> execute
    %Taxon{name: "child0", taxonomy_id: 1} |> create(root, :child) |> execute
    %Taxon{name: "child1", taxonomy_id: 1} |> create(root, :child) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "root", lft: 0, rgt: 5, taxonomy_id: 1}, [
        {%{name: "child0", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{name: "child1", lft: 3, rgt: 4, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "move(node, :root) should move node to root" do
    {_, [_, {_, [{n010, _} | _]}]} = create_tree(1)
    move(n010, :root) |> execute
    assert match(dump(Taxon, %{taxonomy_id: 1}) |> execute,
      [
        {%{name: "n0", lft: 0, rgt: 7, taxonomy_id: 1}, [
          {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
          {%{ name: "n01", lft: 3, rgt: 6, taxonomy_id: 1}, [
            {%{ name: "n011", lft: 4, rgt: 5, taxonomy_id: 1}, []}
          ]}
        ]},
        {%{ name: "n010", lft: 8, rgt: 9, taxonomy_id: 1}, []}
      ]
    )
  end

  test "move(node, target, :child) should move given node to the child of target" do
    {_, [{n00, _}, {n01, _}]} = create_tree(1)
    move(n01, n00, :child) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 8, taxonomy_id: 1}, [
          {%{ name: "n01", lft: 2, rgt: 7, taxonomy_id: 1}, [
            {%{ name: "n010", lft: 3, rgt: 4, taxonomy_id: 1}, []},
            {%{ name: "n011", lft: 5, rgt: 6, taxonomy_id: 1}, []}
          ]}
        ]}
      ]}
    )
  end

  test "move(node, target, :left) should move given node to the left of target" do
    {_, [{n00, _}, {n01, _}]} = create_tree(1)
    move(n01, n00, :left) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n01", lft: 1, rgt: 6, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 2, rgt: 3, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 4, rgt: 5, taxonomy_id: 1}, []}
        ]},
        {%{ name: "n00", lft: 7, rgt: 8, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "move(node, target, :right) should move given node to the right of target" do
    {_, [{n00, _}, {n01, _}]} = create_tree(1)
    move(n00, n01, :right) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n01", lft: 1, rgt: 6, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 2, rgt: 3, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 4, rgt: 5, taxonomy_id: 1}, []}
        ]},
        {%{ name: "n00", lft: 7, rgt: 8, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "move(root_node, :root) should execute without error" do
    {n0, _} = create_tree(1)
    move(n0, :root) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 3, rgt: 8, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 4, rgt: 5, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}, []}
        ]}
      ]}
    )
  end

  test "move(child_node, parent_node, :child) should move given child to the end of children of parent" do
    {n0, [{n00, _}, _]} = create_tree(1)

    move(n00, n0, :child) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n01", lft: 1, rgt: 6, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 2, rgt: 3, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 4, rgt: 5, taxonomy_id: 1}, []}
        ]},
        {%{ name: "n00", lft: 7, rgt: 8, taxonomy_id: 1}, []}
      ]}
    )
  end

  test "move(last_child_node, parent_node, :child) should do nothing" do
    {n0, [_, {n01, _}]} = create_tree(1)

    move(n01, n0, :child) |> execute
    assert match(dump_one(Taxon, %{taxonomy_id: 1}) |> execute,
      {%{name: "n0", lft: 0, rgt: 9, taxonomy_id: 1}, [
        {%{ name: "n00", lft: 1, rgt: 2, taxonomy_id: 1}, []},
        {%{ name: "n01", lft: 3, rgt: 8, taxonomy_id: 1}, [
          {%{ name: "n010", lft: 4, rgt: 5, taxonomy_id: 1}, []},
          {%{ name: "n011", lft: 6, rgt: 7, taxonomy_id: 1}, []}
        ]}
      ]}
    )
  end
end
