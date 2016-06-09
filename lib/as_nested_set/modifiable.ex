defmodule AsNestedSet.Modifiable do

  @type position :: :left | :right | :child

  import Ecto.Query

  defmacro __using__(args) do
    repo = Keyword.fetch!(args, :repo)
    quote do

      @repo unquote(repo)

      def create(target, new_model, position) when is_atom(position) do
        AsNestedSet.do_create(__MODULE__, @repo, target, new_model, position)
      end

      def right_most(scope) when is_list(scope) do
        from q in __MODULE__,
          select: max(field(q, ^right_column))
        |> scoped_query
        |> @repo.one!
      end
    end
  end

  @spec do_create(atom, Module.t, any, any, position) :: :ok | {:err, any}
  def do_create(module, repo, target, new_model, position) do
    case validate_create(module, target, new_model) do
      :ok -> do_safe_create(module, repo, target, new_model, position)
      error -> error
    end
  end

  defp do_safe_create(module, repo, target, new_model, :left) do
    left = module.left(target)
    left_column = module.left_column
    right_column = module.right_column
    from(q in module,
      where: field(q, ^module.left_column) >= ^left,
      update: [inc: ^[{left_column, 2}, {right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> repo.update_all([])

    new_model
    |> module.left(left)
    |> module.right(left + 1)
    |> module.parent_id(module.parent_id(target))
    |> repo.insert!
  end

  defp do_safe_create(module, repo, target, new_model, :right) do
    right = module.right(target)
    left_column = module.left_column
    right_column = module.right_column
    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{left_column, 2}, {right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> repo.update_all([])

    new_model
    |> module.left(right + 1)
    |> module.right(right + 2)
    |> module.parent_id(module.parent_id(target))
    |> repo.insert!
  end

  defp do_safe_create(module, repo, target, new_model, :child) do
    right = module.right(target)
    from(q in module,
      where: field(q, ^module.left_column) > ^right,
      update: [inc: ^[{module.left_column, 2}, {module.right_column, 2}]]
    )
    |> module.scoped_query(target)
    |> repo.update_all([])

    target
    |> module.right(right + 2)
    |> repo.update

    new_model
    |> module.left(right)
    |> module.right(right + 1)
    |> repo.insert!
  end

  defp do_safe_create(module, repo, target, new_model, :root) do
    right_most = module.right_most(target)
    from( q in module,
      update: [inc: ^[{module.left_column, 1}, {module.right_column, 1}]]
    )
    |> module.scoped_query(target)
    |> repo.update_all([])

    new_model = new_model
    |> module.left(0)
    |> module.right(right_most + 2)
    |> repo.insert!

    target
    |> module.parent_id(Map.fetch(new_model, module.parent_id_column))
    |> repo.update
  end

  defp validate_create(module, parent, new_model) do
    cond do
      !module.same_scope?(parent, new_model) -> {:err, :not_the_same_scope}
      true -> :ok
    end
  end
end
