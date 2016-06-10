defmodule AsNestedSet.Modifiable do

  @type position :: :left | :right | :child

  import Ecto.Query

  defmacro __using__(args) do
    quote do

      def create(target \\ nil, new_model, position) when is_atom(position) do
        AsNestedSet.Modifiable.do_create(__MODULE__, target, new_model, position)
      end

      def delete(model) do
        AsNestedSet.Modifiable.do_delete(__MODULE__, model)
      end
    end
  end

  @spec do_delete(Module.t, any) :: boolean
  def do_delete(module, model) do
    left = module.left(model)
    right = module.right(model)
    width = right - left + 1
    from(q in module,
      where: field(q, ^module.left_column) >= ^left and field(q, ^module.left_column) <= ^right
    )
    |> module.scoped_query(model)
    |> module.repo.delete_all([])

    from(q in module,
      where: field(q, ^module.right_column) > ^right,
      update: [inc: ^[{module.right_column, -width}]]
    )
    |> module.scoped_query(model)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{module.left_column, -width}]]
    )
    |> module.scoped_query(model)
    |> module.repo.update_all([])
  end

  @spec do_create(Module.t, any, any, position) :: :ok | {:err, any}
  def do_create(module, target, new_model, position) do
    case validate_create(module, target, new_model, position) do
      :ok -> do_safe_create(module, target, new_model, position)
      error -> error
    end
  end

  defp do_safe_create(module, target, new_model, :left) do
    left = module.left(target)
    # update all the left and right column
    from(q in module,
      where: field(q, ^module.left_column) >= ^left,
      update: [inc: ^[{module.left_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.right_column) > ^left,
      update: [inc: ^[{module.right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    # insert the new model
    new_model
    |> module.changeset(Map.new([
        {module.left_column, left},
        {module.right_column, left + 1},
        {module.parent_id_column, module.parent_id(target)}
      ]))
    |> module.repo.insert!
  end

  defp do_safe_create(module, target, new_model, :right) do
    right = module.right(target)
    # update all the left and right column
    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{module.left_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.right_column) > ^right,
      update: [inc: ^[{module.right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    # insert new model
    new_model
    |> module.changeset(Map.new([
        {module.left_column, right + 1},
        {module.right_column, right + 2},
        {module.parent_id_column, module.parent_id(target)}
      ]))
    |> module.repo.insert!
  end

  defp do_safe_create(module, target, new_model, :child) do
    right = module.right(target)
    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{module.left_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.right_column) >= ^right,
      update: [inc: ^[{module.right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    new_model
    |> module.changeset(Map.new([
        {module.left_column, right},
        {module.right_column, right + 1},
        {module.parent_id_column, module.node_id(target)}
      ]))
    |> module.repo.insert!
  end

  defp do_safe_create(module, target, new_model, :root) do
    right_most = module.right_most(new_model) || -1
    from( q in module,
      update: [inc: ^[{module.left_column, 1}, {module.right_column, 1}]]
    )
    |> module.scoped_query(new_model)
    |> module.repo.update_all([])

    new_model = new_model
    |> module.left(0)
    |> module.right(right_most + 2)
    |> module.repo.insert!

    from( q in module,
      where: is_nil(field(q, ^module.parent_id_column)) and field(q, ^module.left_column) == 1,
      update: [set: ^[{module.parent_id_column, module.node_id(new_model)}]]
    )
    |> module.scoped_query(new_model)
    |> module.repo.update_all([])

    new_model
  end

  defp validate_create(module, parent, new_model, position) do
    cond do
      parent == nil && position != :root -> {:err, :target_is_required}
      position != :root && !module.same_scope?(parent, new_model) -> {:err, :not_the_same_scope}
      true -> :ok
    end
  end
end
