defmodule AsNestedSet.Modifiable do

  @type position :: :left | :right | :child | :parent

  import Ecto.Query
  import AsNestedSet.Helper

  @spec create(AsNestedSet.t, AsNestedSet.t, position) :: AsNestedSet.executable
  def create(new_model, target \\ nil, position) when is_atom(position) do
    fn repo ->
      case validate_create(new_model, target, position) do
        :ok -> do_safe_create(repo, new_model, do_reload(repo, target), position)
        error -> error
      end
    end
  end

  @spec reload(AsNestedSet.t) :: AsNestedSet.executable
  def reload(model) do
    fn repo ->
      do_reload(repo, model)
    end
  end

  defp validate_create(new_model, parent, position) do
    cond do
      parent == nil && position != :root -> {:error, :target_is_required}
      position != :root && !AsNestedSet.Scoped.same_scope?(parent, new_model) -> {:error, :not_the_same_scope}
      true -> :ok
    end
  end

  defp do_safe_create(repo, %{__struct__: struct} = new_model, target, :left) do
    left = get_field(target, :left)
    left_column = get_column_name(target, :left)
    right_column = get_column_name(target, :right)
    # update all the left and right column
    from(q in struct,
      where: field(q, ^left_column) >= ^left,
      update: [inc: ^[{left_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    from(q in struct,
      where: field(q, ^right_column) > ^left,
      update: [inc: ^[{right_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])


    parent_id_column = get_column_name(target, :parent_id)
    parent_id = get_field(target, :parent_id)
    # insert the new model
    new_model
    |> struct.changeset(Map.new([
        {left_column, left},
        {right_column, left + 1},
        {parent_id_column, parent_id}
      ]))
    |> repo.insert!
  end

  defp do_safe_create(repo, %{__struct__: struct} = new_model, target, :right) do
    right = get_field(target, :right)
    left_column = get_column_name(target, :left)
    # update all the left and right column
    from(q in struct,
      where: field(q, ^left_column) > ^right,
      update: [inc: ^[{left_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    right_column = get_column_name(target, :right)
    from(q in struct,
      where: field(q, ^right_column) > ^right,
      update: [inc: ^[{right_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    parent_id_column = get_column_name(target, :parent_id)
    parent_id = get_field(target, :parent_id)
    # insert new model
    new_model
    |> struct.changeset(Map.new([
        {left_column, right + 1},
        {right_column, right + 2},
        {parent_id_column, parent_id}
      ]))
    |> repo.insert!
  end

  defp do_safe_create(repo, %{__struct__: struct} = new_model, target, :child) do

    left_column = get_column_name(target, :left)

    right = get_field(target, :right)
    from(q in struct,
      where: field(q, ^left_column) > ^right,
      update: [inc: ^[{left_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    right_column = get_column_name(target, :right)
    from(q in struct,
      where: field(q, ^right_column) >= ^right,
      update: [inc: ^[{right_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])


    parent_id_column = get_column_name(target, :parent_id)
    node_id = get_field(target, :node_id)
    new_model
    |> struct.changeset(Map.new([
        {left_column, right},
        {right_column, right + 1},
        {parent_id_column, node_id}
      ]))
    |> repo.insert!
  end

  defp do_safe_create(repo, %{__struct__: struct} = new_model, _target, :root) do
    right_most = AsNestedSet.Queriable.right_most(struct, new_model).(repo) || -1

    new_model = new_model
    |> set_field(:left, right_most + 1)
    |> set_field(:right, right_most + 2)
    |> set_field(:parent_id, nil)
    |> repo.insert!

    new_model
  end

  defp do_safe_create(repo, %{__struct__: struct} = new_model, target, :parent) do
    right = get_field(target, :right)
    left = get_field(target, :left)

    right_column = get_column_name(target, :right)
    from(q in struct,
      where: field(q, ^right_column) > ^right,
      update: [inc: ^[{right_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    left_column = get_column_name(target, :left)
    from(q in struct,
      where: field(q, ^left_column) > ^right,
      update: [inc: ^[{left_column, 2}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    from(q in struct,
      where: field(q, ^left_column) >= ^left and field(q, ^right_column) <= ^right,
      update: [inc: ^[{right_column, 1}, {left_column, 1}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    parent_id = get_field(target, :parent_id)
    new_model = new_model
    |> set_field(:left, left)
    |> set_field(:right, right + 2)
    |> set_field(:parent_id, parent_id)
    |> repo.insert!

    node_id = get_field(target, :node_id)
    node_id_column = get_column_name(target, :node_id)
    parent_id_column = get_column_name(target, :parent_id)

    new_model_id = get_field(new_model, :node_id)

    from(q in struct,
      where: field(q, ^node_id_column) == ^node_id,
      update: [set: ^[{parent_id_column, new_model_id}]]
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.update_all([])

    new_model
  end

  defp do_reload(_repo, nil), do: nil

  defp do_reload(repo, %{__struct__: struct} = target) do
    node_id = get_field(target, :node_id)
    node_id_column = get_column_name(target, :node_id)
    from(q in struct,
      where: field(q, ^node_id_column) == ^node_id,
      limit: 1
    )
    |> AsNestedSet.Scoped.scoped_query(target)
    |> repo.one
  end

  @spec delete(AsNestedSet.t) :: AsNestedSet.exectuable
  def delete(%{__struct__: struct} = model) do
    fn repo ->
      left = get_field(model, :left)
      right = get_field(model, :right)
      width = right - left + 1

      left_column = get_column_name(model, :left)
      right_column = get_column_name(model, :right)

      from(q in struct,
        where: field(q, ^left_column) >= ^left and field(q, ^left_column) <= ^right
      )
      |> AsNestedSet.Scoped.scoped_query(model)
      |> repo.delete_all([])

      from(q in struct,
        where: field(q, ^right_column) > ^right,
        update: [inc: ^[{right_column, -width}]]
      )
      |> AsNestedSet.Scoped.scoped_query(model)
      |> repo.update_all([])

      from(q in struct,
        where: field(q, ^left_column) > ^right,
        update: [inc: ^[{left_column, -width}]]
      )
      |> AsNestedSet.Scoped.scoped_query(model)
      |> repo.update_all([])
    end
  end


end
