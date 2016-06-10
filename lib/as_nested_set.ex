defmodule AsNestedSet do
  defmacro __using__(args) do
    scope = Keyword.get(args, :scope, [])
    repo = Keyword.fetch!(args, :repo)
    quote do
      use AsNestedSet.Model
      use AsNestedSet.Repo, repo: unquote(repo)
      use AsNestedSet.Scoped, scope: unquote(scope)
      use AsNestedSet.Queriable
      use AsNestedSet.Modifiable
    end
  end
end
