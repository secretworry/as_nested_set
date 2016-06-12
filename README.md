# as_nested_set

**An [ecto](https://github.com/elixir-lang/ecto) based [Nested set model](https://en.wikipedia.org/wiki/Nested_set_model) implementation for database**

## Installation

Add as_nested_set to your list of dependencies in `mix.exs`:

      # use the stable version
      def deps do
        [{:as_nested_set, "~> 0.1", app: false}]
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
  use AsNestedSet, repo: AsNestedSet.TestRepo, scope: [:taxonomy_id]
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
  use AsNestedSet, repo: AsNestedSet.TestRepo, scope: [:taxonomy_id]
  # ...
end
```

  * `scope`: (required) a list of column names which restrict what is to be considered within the same tree(same scope).
  * `repo`: (required) the name of the repo to operate on

## Model Operations

Once you have set up you model, you can then

Add a new node

```elixir
target = Repo.find!(Taxon, 1)
# add to left
Taxon.add(target, %Taxon{name: "left", taxonomy_id: 1}, :left)
# add to right
Taxon.add(target, %Taxon{name: "right", taxonomy_id: 1}, :right)
# add as first child
Taxon.add(target, %Taxon{name: "child", taxonomy_id: 1}, :child)

# add as root
Taxon.add(%Taxon{name: "root", taxonomy_id: 1}, :root)
```

Remove a specified node and all its descendants

```elixir
target = Repo.find!(Taxon, 1)
Taxon.remove(target)
```

Query different nodes

```elixir

# find all children of target
Taxon.children(target)

# find all the leaves for given scope
Taxon.leaves(%{taxonomy_id: 1})

# find all descendants
Taxon.descendants(target)
# include self
Taxon.self_and_descendants(target)

# find all ancestors
Taxon.ancestors(target)

#find all siblings (self included)
Taxon.self_and_siblings(target)

```
