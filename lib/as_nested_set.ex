defmodule AsNestedSet do
  defmacro __using__(args) do
    scope = Keyword.get(args, :scope, [])
    quote do
      use AsNestedSet.Model
      use AsNestedSet.Scoped, scope: unquote(scope)
    end
  end

  @type t :: struct

  @type executable :: (Ecto.Repo.t -> any)

  @spec defined?(struct) :: boolean
  def defined?(%{__struct__: struct}) do
    try do
      struct.__as_nested_set_fields__()
      true
    rescue
      UndefinedFunctionError ->
        false
    end
  end
  def defined?(_), do: false

  @spec execute((Ecto.Repo.t -> any), Ecto.Repo.t) :: any
  def execute(call, repo) do
    call.(repo)
  end

  defdelegate create(new_model, position), to: AsNestedSet.Modifiable
  defdelegate create(new_model, target, position), to: AsNestedSet.Modifiable
  defdelegate reload(model), to: AsNestedSet.Modifiable
  defdelegate delete(model), to: AsNestedSet.Modifiable

  defdelegate self_and_siblings(target), to: AsNestedSet.Queriable
  defdelegate ancestors(target), to: AsNestedSet.Queriable
  defdelegate self_and_descendants(target), to: AsNestedSet.Queriable
  defdelegate root(module, scope), to: AsNestedSet.Queriable
  defdelegate roots(module, scope), to: AsNestedSet.Queriable
  defdelegate descendants(target), to: AsNestedSet.Queriable
  defdelegate leaves(module, scope), to: AsNestedSet.Queriable
  defdelegate children(target), to: AsNestedSet.Queriable
  defdelegate dump(module, scope), to: AsNestedSet.Queriable
  defdelegate dump(module, scope, parent_id), to: AsNestedSet.Queriable
  defdelegate dump_one(module, scope), to: AsNestedSet.Queriable
  defdelegate right_most(module, scope), to: AsNestedSet.Queriable

  defdelegate traverse(module, scope, context, pre, post), to: AsNestedSet.Traversable
  defdelegate traverse(node, context, pre, post), to: AsNestedSet.Traversable
end
