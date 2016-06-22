defmodule AsNestedSet.Queriable do

  import Ecto.Query

  defmacro __using__(args) do
    quote do
      def root(scope) do
        AsNestedSet.Queriable.do_root(__MODULE__, scope)
      end

      def roots(scope) do
        AsNestedSet.Queriable.do_roots(__MODULE__, scope)
      end

      def right_most(scope) do
        AsNestedSet.Queriable.do_right_most(__MODULE__, scope)
      end

      def reload(target) do
        AsNestedSet.Queriable.do_reload(__MODULE__, target)
      end

      def dump(scope) do
        AsNestedSet.Queriable.do_dump(__MODULE__, scope)
      end

      def dump_one(scope) do
        [dump|_] = AsNestedSet.Queriable.do_dump(__MODULE__, scope)
        dump
      end

      def children(target) do
        AsNestedSet.Queriable.do_children(__MODULE__, target)
      end

      def leaves(scope) do
        AsNestedSet.Queriable.do_leaves(__MODULE__, scope)
      end

      def descendants(target) do
        AsNestedSet.Queriable.do_descendants(__MODULE__, target)
      end

      def self_and_descendants(target) do
        AsNestedSet.Queriable.do_self_and_descendants(__MODULE__, target)
      end

      def ancestors(target) do
        AsNestedSet.Queriable.do_ancestors(__MODULE__, target)
      end

      def self_and_siblings(target) do
        AsNestedSet.Queriable.do_self_and_siblings(__MODULE__, target)
      end
    end
  end

  def do_self_and_siblings(module, target) do
    from(q in module,
      where: field(q, ^module.parent_id_column) == ^module.parent_id(target),
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(target)
    |> module.repo.all
  end

  def do_ancestors(module, target) do
    left = module.left(target)
    right = module.right(target)
    from(q in module,
      where: field(q, ^module.left_column) < ^left and field(q, ^module.right_column) > ^right,
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(target)
    |> module.repo.all
  end

  def do_self_and_descendants(module, target) do
    left = module.left(target)
    right = module.right(target)
    from(q in module,
      where: field(q, ^module.left_column) >= ^left and field(q, ^module.right_column) <= ^right,
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(target)
    |> module.repo.all
  end

  def do_root(module, scope) do
    from(q in module,
      where: is_nil(field(q, ^module.parent_id_column)),
      limit: 1
    )
    |> module.scoped_query(scope)
    |> module.repo.one
  end

  def do_roots(module, scope) do
    from(q in module,
      where: is_nil(field(q, ^module.parent_id_column)),
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(scope)
    |> module.repo.all
  end

  def do_descendants(module, target) do
    left = module.left(target)
    right = module.right(target)
    from(q in module,
      where: field(q, ^module.left_column) > ^left and field(q, ^module.right_column) < ^right,
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(target)
    |> module.repo.all
  end

  def do_leaves(module, scope) do
    from(q in module,
      where: fragment("? - ?", field(q, ^module.right_column), field(q, ^module.left_column)) == 1,
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(scope)
    |> module.repo.all
  end

  def do_children(module, target) do
    from(q in module,
      where: field(q, ^module.parent_id_column) == ^module.node_id(target),
      order_by: ^[module.left_column]
    )
    |> module.scoped_query(target)
    |> module.repo.all
  end

  def do_dump(module, scope, parent_id \\ nil) do
    children = if parent_id do
      from(q in module,
        where: field(q, ^module.parent_id_column) == ^parent_id,
        order_by: ^[module.left_column]
      )
    else
      from(q in module,
        where: is_nil(field(q, ^module.parent_id_column)),
        order_by: ^[module.left_column]
      )
    end
    |> module.scoped_query(scope)
    |> module.repo.all
    Enum.map(children, fn(child) ->
      {child, do_dump(module, scope, module.node_id(child))}
    end)
  end

  def do_reload(module, target) do
    from(q in module,
      where: field(q, ^module.node_id_column) == ^module.node_id(target)
    )
    |> module.scoped_query(target)
    |> module.repo.one!
  end

  def do_right_most(module, scope) do
    from(q in module,
      select: max(field(q, ^module.right_column))
    )
    |> module.scoped_query(scope)
    |> module.repo.one!
  end

end
