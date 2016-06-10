defmodule AsNestedSet.Queriable do

  import Ecto.Query

  defmacro __using__(args) do
    quote do
      def right_most(scope) do
        AsNestedSet.Queriable.do_right_most(__MODULE__, scope)
      end

      def reload(target) do
        AsNestedSet.Queriable.do_reload(__MODULE__, target)
      end

      def dump(scope) do
        AsNestedSet.Queriable.do_dump(__MODULE__, scope)
      end
    end
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
