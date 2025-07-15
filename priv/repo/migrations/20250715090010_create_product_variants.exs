defmodule HomeWare.Repo.Migrations.CreateProductVariants do
  use Ecto.Migration

  def change do
    create table(:product_variants, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :option_name, :string, null: false
      add :sku, :string, null: false
      add :price_override, :decimal, precision: 10, scale: 2
      add :quantity, :integer, default: 0, null: false
      add :is_active, :boolean, default: true, null: false
      add :product_id, references(:products, on_delete: :delete_all, type: :uuid), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:product_variants, [:sku])
    create index(:product_variants, [:product_id])
    create index(:product_variants, [:is_active])
  end
end
