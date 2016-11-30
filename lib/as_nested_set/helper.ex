defmodule AsNestedSet.Helper do

  def get_column_name(%{__struct__: struct}, field) do
    get_column_name(struct, field)
  end

  def get_column_name(module, field) when is_atom(module) do
    module.__as_nested_set_column_name__(field)
  end

  def get_field(%{__struct__: struct} = model, field) do
    struct.__as_nested_set_get_field__(model, field)
  end

  def set_field(%{__struct__: struct} = model, field, value) do
    struct.__as_nested_set_set_field__(model, field, value)
  end

  def fields(module) when is_atom(module) do
    module.__as_nested_set_fields__()
  end


end