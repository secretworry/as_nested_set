# as_nested_set

[![Build Status](https://travis-ci.com/secretworry/as_nested_set.svg?branch=master)](https://travis-ci.org/secretworry/as_nested_set)
[![Coveralls Coverage](https://img.shields.io/coveralls/secretworry/as_nested_set.svg)](https://coveralls.io/github/secretworry/as_nested_set)
[![Hex.pm](https://img.shields.io/hexpm/v/as_nested_set.svg)](http://hex.pm/packages/as_nested_set)

**An [ecto](https://github.com/elixir-lang/ecto) based [Nested set model](https://en.wikipedia.org/wiki/Nested_set_model) implementation for database**

## Installation

Add as_nested_set to your list of dependencies in `mix.exs`:

```elixir
  # use the stable version
  def deps do
    [{:as_nested_set, "~> 3.3"}]
  end

  # use the latest version
  def deps do
    [{:as_nested_set, github: "https://github.com/secretworry/as_nested_set.git"}]
  end
```

## Usage

To make use of `as_nested_set`, 4 fields( `id`, `lft`, `rgt` and `parent_id`) are required for your model. The name of those fields are configurable.

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

You can config the name of required fields through attributes:

```elixir
defmodule AsNestedSet.Taxon do
  @right_column :right
  @left_column :left
  @node_id_column :node_id
  @parent_id_column :pid
  # ...
end
```

  * `@right_column`: column name for the right boundary (defaults to `lft`, since left is a reserved keyword for Mysql)
  * `@left_column`: column name for the left boundary (defaults to `rgt`, reserved too)
  * `@node_id_column`:  specifies the name for the node id column (defaults to `id`, i.e. the id of the model, change this if you want to have a different id, or you id field is different)
  * `@parent_id_column`: specifies the name for the parent id column (defaults to `parent_id`)

You can also pass following arguments to modify its behavior:

```elixir
defmodule AsNestedSet.Taxon do
  use AsNestedSet, scope: [:taxonomy_id]
  # ...
end
```

  * `scope`: (optional) a list of column names which restrict what are to be considered within the same tree(same scope). When ignored, all the nodes will be considered under the same tree.

## Model Operations

Once you have set up you model, you can then

Add new nodes

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

# FAQ

## How to ensure the consistency

*We recommend users to use a transaction to wrap all the operations in the production environment*

We introduced the `@type executable`( a delayed execution ) as the return value of each API, so using transaction or not and how granular the transaction should be are all up to users.

In general, almost all modifications of a nested set can be done in one SQL, but we can't express some of them using ecto's DSL( ecto doesn't support `case-when` in update query ), so users having concurrent modifications *must* wrap `AsNestedSet.execute(call, repo)` in a Transaction, for example

```elixir
exec = node |> AsNestedSet.move(:root)
Repo.transaction fn -> AsNestedSet.execute(exec, Repo) end
```

The `node` passed in as an argument might has changed after loaded from db, we will reload it from DB before use it, so there is no need to wrap the `load` and the `execute` in the same transaction

```elixir
# This is not necessary
Repo.transaction fn ->
	node = loadNode()
	node |> AsNestedSet.move(:root) |> AsNestedSet.execute(Repo) # We will reload the node passed in
end
```

But if you want to ensure consistency across multiple `execute`s , to avoid the racing condition, you have to isolate them by wrap them in different transactions.

## How to move a node to be the n-th child of a target

Be default, after using `AsNestedSet.move(node, target, :child)`, you move the `node` to be the right-most child of the `target`, because we can know the `left` and `right` of the target right way, but to find out the proper `right` and `left` for n-th child requires more operations.

To achieve the goal, you should:
  1. Query the n-th child or (n-1)th child of the target by `AsNestedSet.children(target)`,
  2. Use `move(node, n_th_child, :left)` and `move(node, n_1_th_child, :right)` respectively.

## Ecto 2.x

`Ecto` is upgrading to 3.0, with a clear API and a lot lot of bug fixes. Please consider to upgrade for your projects too:)
We will not support 2.x in our public releases, but if you are using Ecto 2.x, you can get the latest updates by using branch `ecto-2.x`

# Contributors

* [@SagarKarwande](https://github.com/SagarKarwande)
* [@oyeb](https://github.com/oyeb)
* [@nicholasjhenry](https://github.com/nicholasjhenry)
* [@montebrown](https://github.com/montebrown)

# Special thanks

* Thanks [Travis CI](https://travis-ci.com/) for providing free and convenient integration test
