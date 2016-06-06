defmodule AsNestedSet.Model do

  defmacro __using__(_) do
    quote do
      @left_column :left
      @right_column :right
      @parent_id_column :parent_id
      @before_compile AsNestedSet.Model
    end
  end

  defmacro __before_compile__(env) do
    Enum.reduce([:parent_id, :left, :right], nil, &define_accessor(&1, &2, env))
    |> define_queriers(env)
  end

  defp define_accessor(name, acc, env) do
    attribute_name = String.to_atom("#{name}_column")
    column_name = Module.get_attribute(env.module, attribute_name)
    quote do
      unquote(acc)
      def unquote(name)(model) do
        model.unquote(column_name)
      end
    end
  end

  defp define_queriers(acc, env) do
    quote do
      unquote(acc)
      def child?(model) do
        parent_id(model) != nil
      end

      def root?(model) do
        parent_id(model) == nil
      end
    end
  end
end
