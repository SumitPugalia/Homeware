defmodule HomeWare.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :brand, :string
      add :model, :string
      add :product_type, :string
      add :product_category, :string
      add :description, :string
      add :dimensions, :map
      add :specifications, :map
      add :price, :decimal, null: false
      add :selling_price, :decimal
      add :images, {:array, :string}, default: []
      add :featured_image, :string

      add :inventory_quantity, :integer, default: 0
      add :is_featured, :boolean, default: false
      add :is_active, :boolean, default: true
      add :category_id, references(:categories, on_delete: :restrict, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:category_id])
    create index(:products, [:is_featured])
    create index(:products, [:is_active])
    create index(:products, [:price])
  end
end
