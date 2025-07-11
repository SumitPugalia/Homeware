defmodule HomeWare.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :order_number, :string
      add :status, :string
      add :subtotal, :decimal
      add :tax_amount, :decimal
      add :shipping_amount, :decimal
      add :discount_amount, :decimal
      add :total_amount, :decimal
      add :currency, :string
      add :notes, :text
      add :tracking_number, :string
      add :shipped_at, :utc_datetime
      add :delivered_at, :utc_datetime
      add :cancelled_at, :utc_datetime
      add :cancellation_reason, :text
      add :user_id, references(:users, on_delete: :restrict, type: :uuid)
      add :shipping_address_id, references(:addresses, on_delete: :restrict, type: :uuid)
      add :billing_address_id, references(:addresses, on_delete: :restrict, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:orders, [:order_number])
    create index(:orders, [:user_id])
    create index(:orders, [:status])
    create index(:orders, [:inserted_at])
  end
end
