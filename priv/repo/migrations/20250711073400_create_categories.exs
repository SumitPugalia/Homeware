defmodule HomeWare.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :image_url, :string
      add :parent_id, references(:categories, on_delete: :nilify_all, type: :uuid)
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:slug])
    create index(:categories, [:parent_id])
    create index(:categories, [:is_active])
  end
end
