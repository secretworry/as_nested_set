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
    [
      define_accessors([:node_id, :left, :right, :parent_id], env),
      define_queriers(env)
    ]
  end

  defp define_accessors(names, env) do
    fields = Enum.map(names, fn
      name ->
        attribute_name = String.to_atom("#{name}_column")
        column_name = Module.get_attribute(env.module, attribute_name)
        {name, column_name}
    end) |> Enum.into(%{})

    Enum.map(fields, fn
       {name, column_name}->
        quote do
          def __as_nested_set_field__(unquote(name)) do
            unquote(column_name)
          end
          def __as_nested_set_get_field__(model, unquote(name)) do
            Map.get(model, unquote(column_name))
          end
          def __as_nested_set_set_field__(model, unquote(name), value) do
            Map.put(model, unquote(column_name), value)
          end
        end
    end) ++ [
      quote do
        def __as_nested_set_field__(field) do
          raise ArgumentError, "Unknown AsNestedSet field #{inspect field} for #{inspect __MODULE__}"
        end
        def __as_nested_set_get_field__(model, _), do: nil
        def __as_nested_set_set_field__(model, _, _), do: model
        def __as_nested_set_fields__(), do: unquote(fields |> Macro.escape)
      end
    ]
  end

  defp define_queriers(_env) do
    quote do
      def child?(model) do
        __as_nested_set_get_field__(model, :parent_id) != nil
      end

      def root?(model) do
        __as_nested_set_get_field__(model, :parent_id) == nil
      end
    end
  end
end
