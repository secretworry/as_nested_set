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
    end
  end

  @spec do_same_scope?(any, any, atom) :: boolean
  def do_same_scope?(source, target, scope) do
    Enum.all?(scope, fn field ->
      Map.get(source, field) == Map.get(target, field)
    end)
  end
end
