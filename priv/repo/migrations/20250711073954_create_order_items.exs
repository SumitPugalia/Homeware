defmodule HomeWare.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :quantity, :integer
      add :unit_price, :decimal
      add :total_price, :decimal
      add :product_name, :string
      add :product_sku, :string
      add :order_id, references(:orders, on_delete: :delete_all, type: :uuid)
      add :product_id, references(:products, on_delete: :restrict, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:product_id])
  end
end
