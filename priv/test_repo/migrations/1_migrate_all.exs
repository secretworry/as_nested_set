defmodule AsNestedSet.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:taxons) do
      add :name, :string
      add :taxonomy_id, :id
      add :parent_id, :id
      add :lft, :integer
      add :rgt, :integer

      timestamps()
    end

  end
end
