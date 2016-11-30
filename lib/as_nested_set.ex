defmodule AsNestedSet do
  defmacro __using__(args) do
    scope = Keyword.get(args, :scope, [])
    quote do
      use AsNestedSet.Model
      use AsNestedSet.Scoped, scope: unquote(scope)
    end
  end

  @type t :: struct

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

  def get_field(%{__struct__: struct} = model, field) do
    struct.__as_nested_set_get_field__(model, field)
  end

  def set_field(%{__struct__: struct} = model, field, value) do
    struct.__as_nested_set_set_field__(model, field, value)
  end

  def fields(module) when is_atom(module) do
    module.__as_nested_set_fields__()
  end

  def scope(module) when is_atom(module) do
    module.__as_nested_set_scope__()
  end
end
