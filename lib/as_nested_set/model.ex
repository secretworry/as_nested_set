defmodule AsNestedSet.Model do

  defmacro __using__(_) do
    quote do
      @node_id_column :id
      @left_column :lft
      @right_column :rgt
      @parent_id_column :parent_id
      @before_compile AsNestedSet.Model
    end
  end

  defmacro __before_compile__(env) do
    nil
    |> define_accessors([:node_id, :left, :right, :parent_id], env)
    |> define_queriers(env)
    |> define_column_name_accessors([:node_id_column, :left_column, :right_column, :parent_id_column], env)
  end

  defp define_accessors(acc, names, env) do
    Enum.reduce(names, acc, fn name, acc ->
      attribute_name = String.to_atom("#{name}_column")
      column_name = Module.get_attribute(env.module, attribute_name)
      quote do
        unquote(acc)
        def unquote(name)(model) do
          model.unquote(column_name)
        end
        def unquote(name)(model, value) do
          Map.put(model, unquote(column_name), value)
        end
      end
    end)
  end

  defp define_queriers(acc, _env) do
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

  defp define_column_name_accessors(acc, column_names, env) do
    Enum.reduce(column_names, acc, fn(column_name, acc) ->
      name = Module.get_attribute(env.module, column_name)
      quote do
        unquote(acc)
        def unquote(column_name)() do
          unquote(name)
        end
      end
    end)
  end
end
