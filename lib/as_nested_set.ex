defmodule AsNestedSet do
  defmacro __using__(args) do
    scope = Keyword.get(args, :scope, [])
    quote do
      use AsNestedSet.Model
      use AsNestedSet.Scoped, scope: unquote(scope)
      use AsNestedSet.Queriable
      use AsNestedSet.Modifiable
      use AsNestedSet.Executable
    end
  end
end
