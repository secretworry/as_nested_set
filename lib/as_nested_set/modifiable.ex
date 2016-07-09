defmodule AsNestedSet.Modifiable do

  @type position :: :left | :right | :child | :parent

  import Ecto.Query

  defmacro __using__(_args) do
    quote do

      def create(new_model, target \\ nil, position) when is_atom(position) do
        AsNestedSet.Modifiable.do_create(__MODULE__, new_model, target, position)
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
  def do_create(module, new_model, target, position) do
    case validate_create(module, new_model, target, position) do
      :ok -> do_safe_create(module, new_model, reload(module, target), position)
      error -> error
    end
  end

  defp do_safe_create(module, new_model, target, :left) do
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

  defp do_safe_create(module, new_model, target, :right) do
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

  defp do_safe_create(module, new_model, target, :child) do
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

  defp do_safe_create(module, new_model, _target, :root) do
    right_most = module.right_most(new_model) || -1

    new_model = new_model
    |> module.left(right_most + 1)
    |> module.right(right_most + 2)
    |> module.parent_id(nil)
    |> module.repo.insert!

    new_model
  end

  defp do_safe_create(module, new_model, target, :parent) do
    right = module.right(target)
    left = module.left(target)
    from(q in module,
      where: field(q, ^module.right_column) > ^right,
      update: [inc: ^[{module.right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{module.left_column, 2}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    from(q in module,
      where: field(q, ^module.left_column) >= ^left and field(q, ^module.right_column) <= ^right,
      update: [inc: ^[{module.right_column, 1}, {module.left_column, 1}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    new_model = new_model
    |> module.left(left)
    |> module.right(right + 2)
    |> module.parent_id(module.parent_id(target))
    |> module.repo.insert!

    node_id = module.node_id(target)

    from(q in module,
      where: field(q, ^module.node_id_column) == ^node_id,
      update: [set: ^[{module.parent_id_column, new_model.id}]]
    )
    |> module.scoped_query(target)
    |> module.repo.update_all([])

    new_model
  end

  defp validate_create(module, new_model, parent, position) do
    cond do
      parent == nil && position != :root -> {:err, :target_is_required}
      position != :root && !module.same_scope?(parent, new_model) -> {:err, :not_the_same_scope}
      true -> :ok
    end
  end

  defp reload(module, target) when not is_nil(target) do
    node_id = module.node_id(target)
    from(q in module,
      where: field(q, ^module.node_id_column) == ^node_id,
      limit: 1
    )
    |> module.scoped_query(target)
    |> module.repo.one
  end

  defp reload(module, target) do
    target
  end

end
