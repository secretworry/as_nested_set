# as_nested_set

**An [ecto](https://github.com/elixir-lang/ecto) based [Nested set model](https://en.wikipedia.org/wiki/Nested_set_model) implementation for database**

## Installation

Add as_nested_set to your list of dependencies in `mix.exs`:

      # use the stable version
      def deps do
        [{:as_nested_set, "~> 3.1", app: false}]
      end

      # use the latest version
      def deps do
        [{:as_nested_set, github: "https://github.com/secretworry/as_nested_set.git", app: false}]
      end

## Usage

To make use of `as_nested_set` your model has to have at least 4 fields: `id`, `lft`, `rgt` and `parent_id`. The name of those fields are configurable.

```elixir
defmodule AsNestedSet.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:taxons) do
      add :name, :string
      add :taxonomy_id, :id
      add :parent_id, :id
      add :lft, :integer
      add :rgt, :integer

      timestamps
    end

  end
end
```

Enable the nested set functionality by `use AsNestedSet` on your model

```elixir
defmodule AsNestedSet.Taxon do
  use AsNestedSet, scope: [:taxonomy_id]
  # ...
end
```

## Options

You can config the name of required field through attributes:

```elixir
defmodule AsNestedSet.Taxon do
  @right_column :right
  @left_column :left
  @node_id_column :node_id
  @parent_id_column :pid
  # ...
end
```

  * `@right_column`: column name for right boundary (default to `lft`, since left is a reserved keyword for Mysql)
  * `@left_column`: column name for left boundary (default to `rgt`, reserved too)
  * `@node_id_column`:  specifies the name for the node id column (default to `id`, i.e. the id of the model, change this if you want to have a different id, or you id field is different)
  * `@parent_id_column`: specifies the name for the parent id column (default to `parent_id`)

You can also pass following to modify its behavior:

```elixir
defmodule AsNestedSet.Taxon do
  use AsNestedSet, scope: [:taxonomy_id]
  # ...
end
```

  * `scope`: (optional) a list of column names which restrict what is to be considered within the same tree(same scope). When ignored, all the nodes will be considered under the same tree.

## Model Operations

Once you have set up you model, you can then

Add a new node

```elixir
target = Repo.find!(Taxon, 1)
# add to left
%Taxon{name: "left", taxonomy_id: 1} |> AsNestedSet.create(target, :left) |> AsNestedSet.execute(TestRepo)
# add to right
%Taxon{name: "right", taxonomy_id: 1} |> AsNestedSet.create(target, :right) |> AsNestedSet.execute(TestRepo)
# add as first child
%Taxon{name: "child", taxonomy_id: 1} |> AsNestedSet.create(target, :child) |> AsNestedSet.execute(TestRepo)
# add as parent
%Taxon{name: "parent", taxonomy_id: 1} |> AsNestedSet.create(target, :parent) |> AsNestedSet.execute(TestRepo)

# add as root
%Taxon{name: "root", taxonomy_id: 1} |> AsNestedSet.create(:root) |> AsNestedSet.execute(TestRepo)

# move a node to a new position

node |> AsNestedSet.move(:root) |> AsNestedSet.execute(TestRepo) // move the node to be a new root
node |> AsNestedSet.move(target, :left) |> AsNestedSet.execute(TestRepo) // move the node to the left of the target
node |> AsNestedSet.move(target, :right) |> AsNestedSet.execute(TestRepo) // move the node to the right of the target
node |> AsNestedSet.move(target, :child) |> AsNestedSet.execute(TestRepo) // move the node to be the right-most child of target

```

Remove a specified node and all its descendants

```elixir
target = Repo.find!(Taxon, 1)
AsNestedSet.remove(target) |> AsNestedSet.execute(TestRepo)
```

Query different nodes

```elixir

# find all roots
AsNestedSet.roots(Taxon, %{taxonomy_id: 1}) |> AsNestedSet.execute(TestRepo)

# find all children of target
AsNestedSet.children(target) |> AsNestedSet.execute(TestRepo)

# find all the leaves for given scope
AsNestedSet.leaves(Taxon, %{taxonomy_id: 1}) |> AsNestedSet.execute(TestRepo)

# find all descendants
AsNestedSet.descendants(target) |> AsNestedSet.execute(TestRepo)
# include self
AsNestedSet.self_and_descendants(target) |> AsNestedSet.execute(TestRepo)

# find all ancestors
AsNestedSet.ancestors(target) |> AsNestedSet.execute(TestRepo)

#find all siblings (self included)
AsNestedSet.self_and_siblings(target) |> AsNestedSet.execute(TestRepo)

```

Traverse the tree
```elixir
# traverse a tree with 3 args post callback
AsNestedSet.traverse(Taxon, %{taxonomy_id}, context, fn node, context -> {node, context}, end, fn node, children, context -> {node, context} end) |> AsNestedSet.execute(TestRepo)
# traverse a tree with 2 args post callback
AsNestedSet.traverse(Taxon, %{taxonomy_id}, context, fn node, context -> {node, context}, end, fn node, context -> {node, context} end) |> AsNestedSet.execute(TestRepo)

# traverse a subtree with 3 args post callback
AsNestedSet.traverse(target, context, fn node, context -> {node, context}, end, fn node, children, context -> {node, context} end) |> AsNestedSet.execute(TestRepo)
# traverse a tree with 2 args post callback
AsNestedSet.traverse(target, context, fn node, context -> {node, context}, end, fn node, context -> {node, context} end) |> AsNestedSet.execute(TestRepo)
```

## FAQ

1. How to move a node to be the n-th child of a target

  Be default, after using `AsNestedSet.move(node, target, :child)`, you move the `node` to be the right-most child of the `target`, because we can know the `left` and `right` of the target right way, but to find out the proper `right` and `left` for n-th child requires more operations.

  To achieve the goal, you should
  1. Query the n-th child or (n-1)th child of the target by `AsNestedSet.children(target)`,
  2. Use `move(node, n_th_child, :left)` and `move(node, n_1_th_child, :right)` respectively.
