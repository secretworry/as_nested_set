defmodule AsNestedSet.Repo do
  defmacro __using__(args) do
    repo = Keyword.fetch!(args, :repo)
    quote do
      @repo unquote(repo)

      def repo do
        @repo
      end
    end
  end
end
