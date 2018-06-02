defmodule AsNestedSet.Taxon do
  use Ecto.Schema
  import Ecto.Changeset
  use AsNestedSet, scope: [:taxonomy_id]

  schema "taxons" do

    field :name, :string
    field :taxonomy_id, :integer
    field :parent_id, :integer
    field :lft, :integer
    field :rgt, :integer

    timestamps()
  end

  @required_fields ~w(name taxonomy_id lft rgt)
  @optional_fields ~w(parent_id)


  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
  end
end
