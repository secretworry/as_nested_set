defmodule AsNestedSet.Executable do
  defmacro __using__(_args) do
    quote do
      @spec execute((Ecto.Repo.t -> any), Ecto.Repo.t) :: any
      def execute(call, repo) do
        call.(repo)
      end
    end
  end
end
