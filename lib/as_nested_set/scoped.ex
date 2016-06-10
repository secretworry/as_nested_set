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
      @spec same_scope?(any, any) :: boolean
      def same_scope?(source, target) do
        AsNestedSet.Scoped.do_same_scope?(source, target, unquote(scope))
      end

      @spec scoped_query(Ecto.Query.t, any) :: Ecto.Query.t
      def scoped_query(query, target) do
        AsNestedSet.Scoped.do_scoped_query(__MODULE__, @scope, query, target)
      end

      @spec assign_scope_from(any, any) :: any
      def assign_scope_from(target, source) do
        Enum.reduce(@scope, target, fn(scope, acc) ->
          Map.put(acc, scope, Map.fetch!(source, scope))
        end)
      end

      @spec scope(any) :: Map.t
      def scope(target) do
        Enum.reduce(@scope, %{}, fn(acc, scope) ->
          Map.put(acc, scope, Map.fetch!(target, scope))
        end)
      end
    end
  end

  @spec do_scoped_query(Module.t, [atom], Ecto.Query.t, any) :: Ecto.Query.t
  def do_scoped_query(module, scopes, query, target) do
    Enum.reduce(scopes, query, fn(scope, acc) ->
      from(p in acc,
        where: field(p, ^scope) == ^Map.fetch!(target, scope))
    end)
  end

  @spec do_same_scope?(any, any, atom) :: boolean
  def do_same_scope?(source, target, scope) do
    Enum.all?(scope, fn field ->
      Map.get(source, field) == Map.get(target, field)
    end)
  end
end
