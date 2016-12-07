defmodule AsNestedSet.Queriable do

  import Ecto.Query
  import AsNestedSet.Helper

  def self_and_siblings(%{__struct__: struct} = target) do
    fn repo ->
      parent_id_column = get_column_name(target, :parent_id)
      left_column = get_column_name(target, :left)
      parent_id = get_field(target, :parent_id)
      from(q in struct,
        where: field(q, ^parent_id_column) == ^parent_id,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(target)
      |> repo.all
    end
  end

  def ancestors(%{__struct__: struct} = target) do
    fn repo ->
      left = get_field(target, :left)
      right = get_field(target, :right)
      left_column = get_column_name(target, :left)
      right_column = get_column_name(target, :right)
      from(q in struct,
        where: field(q, ^left_column) < ^left and field(q, ^right_column) > ^right,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(target)
      |> repo.all
    end
  end

  def self_and_descendants(%{__struct__: struct} = target) do
    fn repo ->
      left = get_field(target, :left)
      right = get_field(target, :right)
      left_column = get_column_name(target, :left)
      right_column = get_column_name(target, :right)
      from(q in struct,
        where: field(q, ^left_column) >= ^left and field(q, ^right_column) <= ^right,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(target)
      |> repo.all
    end
  end

  def root(module, scope) when is_atom(module) do
    fn repo ->
      parent_id_column = get_column_name(module, :parent_id)
      from(q in module,
        where: is_nil(field(q, ^parent_id_column)),
        limit: 1
      )
      |> AsNestedSet.Scoped.scoped_query(scope)
      |> repo.one
    end
  end

  def roots(module, scope) when is_atom(module) do
    fn repo ->
      parent_id_column = get_column_name(module, :parent_id)
      left_column = get_column_name(module, :left)
      from(q in module,
        where: is_nil(field(q, ^parent_id_column)),
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(scope)
      |> repo.all
    end
  end

  def descendants(%{__struct__: struct} = target) do
    fn repo ->
      left = get_field(target, :left)
      right = get_field(target, :right)
      left_column = get_column_name(target, :left)
      right_column = get_column_name(target, :right)
      from(q in struct,
        where: field(q, ^left_column) > ^left and field(q, ^right_column) < ^right,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(target)
      |> repo.all
    end
  end

  def leaves(module, scope) when is_atom(module) do
    fn repo ->
      left_column = get_column_name(module, :left)
      right_column = get_column_name(module, :right)
      from(q in module,
        where: fragment("? - ?", field(q, ^right_column), field(q, ^left_column)) == 1,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(scope)
      |> repo.all
    end
  end

  def children(%{__struct__: struct} = target) do
    fn repo ->
      parent_id_column = get_column_name(target, :parent_id)
      left_column = get_column_name(target, :left)
      node_id = get_field(target, :node_id)
      from(q in struct,
        where: field(q, ^parent_id_column) == ^node_id,
        order_by: ^[left_column]
      )
      |> AsNestedSet.Scoped.scoped_query(target)
      |> repo.all
    end
  end

  def dump(module, scope, parent_id \\ nil) do
    fn repo ->
      parent_id_column = get_column_name(module, :parent_id)
      left_column = get_column_name(module, :left)

      children = if parent_id do
        from(q in module,
          where: field(q, ^parent_id_column) == ^parent_id,
          order_by: ^[left_column]
        )
      else
        from(q in module,
          where: is_nil(field(q, ^parent_id_column)),
          order_by: ^[left_column]
        )
      end
      |> AsNestedSet.Scoped.scoped_query(scope)
      |> repo.all

      Enum.map(children, fn(child) ->
        node_id = get_field(child, :node_id)
        {child, dump(module, scope, node_id).(repo)}
      end)
    end
  end

  def dump_one(module, scope) do
    fn repo ->
      case dump(module, scope).(repo) do
        [dump|_] -> dump
        error -> error
      end
    end
  end


  def right_most(module, scope) when is_atom(module) do
    fn repo ->
      right_column = get_column_name(module, :right)
      from(q in module,
        select: max(field(q, ^right_column))
      )
      |> AsNestedSet.Scoped.scoped_query(scope)
      |> repo.one!
    end
  end

  def right_most(%{__struct__: struct} = target) do
    fn repo ->
      right_most(struct, target).(repo)
    end
  end
end
