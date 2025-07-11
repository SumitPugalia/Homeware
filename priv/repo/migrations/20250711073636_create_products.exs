defmodule HomeWare.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :short_description, :string
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :compare_at_price, :decimal, precision: 10, scale: 2
      add :sku, :string
      add :brand, :string
      add :model, :string
      add :weight, :decimal, precision: 8, scale: 2
      add :dimensions, :jsonb
      add :specifications, :jsonb
      add :images, {:array, :string}, default: []
      add :featured_image, :string
      add :inventory_quantity, :integer, default: 0, null: false
      add :is_featured, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false
      add :category_id, references(:categories, on_delete: :restrict)
      add :average_rating, :decimal, precision: 3, scale: 2, default: 0.0
      add :review_count, :integer, default: 0

      timestamps()
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
