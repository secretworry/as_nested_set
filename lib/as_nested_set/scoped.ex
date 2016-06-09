defmodule AsNestedSet.Scoped do
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
        Enum.reduce(@scope, query, fn(acc, scope) ->
          from p in acc,
            where: field(^scope, p) == ^target.scope
        end)
      end

      @spec assign_scope(any, any) :: any
      def assign_scope_from(target, source) do
        Enum.reduce(@scope, target, fn(acc, scope) ->
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

  @spec do_same_scope?(any, any, atom) :: boolean
  def do_same_scope?(source, target, scope) do
    Enum.all?(scope, fn field ->
      Map.get(source, field) == Map.get(target, field)
    end)
  end
end
