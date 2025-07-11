defmodule HomeWare.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :order_number, :string, null: false
      add :status, :string, null: false
      add :subtotal, :decimal, precision: 10, scale: 2, null: false
      add :tax_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
      add :shipping_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
      add :discount_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "USD", null: false
      add :notes, :text
      add :tracking_number, :string
      add :shipped_at, :naive_datetime
      add :delivered_at, :naive_datetime
      add :cancelled_at, :naive_datetime
      add :cancellation_reason, :text
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :shipping_address_id, references(:addresses, on_delete: :restrict), null: false
      add :billing_address_id, references(:addresses, on_delete: :restrict), null: false

      timestamps()
    end

    create unique_index(:orders, [:order_number])
    create index(:orders, [:user_id])
    create index(:orders, [:status])
    create index(:orders, [:inserted_at])
  end
end
