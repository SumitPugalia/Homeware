defmodule HomeWare.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :slug, :string
      add :description, :text
      add :short_description, :string
      add :price, :decimal
      add :compare_at_price, :decimal
      add :sku, :string
      add :brand, :string
      add :model, :string
      add :weight, :decimal
      add :dimensions, :jsonb
      add :specifications, :jsonb
      add :images, {:array, :string}, default: []
      add :featured_image, :string
      add :inventory_quantity, :integer, default: 0
      add :is_featured, :boolean, default: false
      add :is_active, :boolean, default: true
      add :category_id, references(:categories, on_delete: :restrict, type: :uuid)
      add :average_rating, :decimal
      add :review_count, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:slug])
    create unique_index(:products, [:sku])
    create index(:products, [:category_id])
    create index(:products, [:brand])
    create index(:products, [:is_featured])
    create index(:products, [:is_active])
    create index(:products, [:price])
    create index(:products, [:average_rating])
  end
end
