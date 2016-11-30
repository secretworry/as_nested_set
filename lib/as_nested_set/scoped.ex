defmodule AsNestedSet.Scoped do

  import Ecto.Query

  defmacro __using__(args) do
    quote do
      @scope unquote(Keyword.get(args, :scope, []))
      @before_compile AsNestedSet.Scoped
    end
  end

  defmacro __before_compile__(env) do
    scope = Module.get_attribute(env.module, :scope)
    quote do
      def __as_nested_set_scope__(), do: unquote(scope)
    end
  end

  @spec same_scope?(AsNestedSet.t, AsNestedSet.t) :: boolean
  def same_scope?(source, target) do
    AsNestedSet.defined?(source)
    && AsNestedSet.defined?(target)
    && source.__struct__ == target.__struct__
    && do_same_scope?(source, target)
  end

  @spec scoped_query(Ecto.Query.t, AsNestedSet.t) :: Ecto.Query.t
  def scoped_query(query, target) do
    {_, module} = query
    assert_as_nested_set(module)
    do_scoped_query(query, target, module.__as_nested_set_scope__)
  end

  @spec assign_scope_from(any, any) :: any
  def assign_scope_from(%{__struct__: struct} = target, %{__struct__: struct} = source) do
    assert_as_nested_set(struct)
    scope = struct.__as_nested_set_scope__
    Enum.reduce(scope, target, fn(scope, acc) ->
      Map.put(acc, scope, Map.fetch!(source, scope))
    end)
  end

  @spec scope(any) :: Map.t
  def scope(%{__struct__: struct} = target) do
    assert_as_nested_set(struct)
    scope = struct.__as_nested_set_scope__
    Enum.reduce(scope, %{}, fn scope, acc ->
      Map.put(acc, scope, Map.fetch!(target, scope))
    end)
  end

  defp do_scoped_query(query, target, scopes) do
    Enum.reduce(scopes, query, fn(scope, acc) ->
      from(p in acc,
        where: field(p, ^scope) == ^Map.fetch!(target, scope))
    end)
  end

  defp do_same_scope?(source, target) do
    scope = source.__as_nested_set_scope__
    Enum.all?(scope, fn field ->
      Map.get(source, field) == Map.get(target, field)
    end)
  end

  defp assert_as_nested_set(module) do
    if !AsNestedSet.defined?(module) do
      raise ArgumentError, "the module #{inspect module} specified in query doesn't defined as AsNestedSet''"
    end
  end
end
