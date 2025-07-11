defmodule HomeWare.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :quantity, :integer, null: false, default: 1
      add :session_id, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :product_id, references(:products, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:cart_items, [:session_id])
    create index(:cart_items, [:user_id])
    create index(:cart_items, [:product_id])
    create unique_index(:cart_items, [:session_id, :product_id], name: :cart_items_session_product_unique_index)
    create unique_index(:cart_items, [:user_id, :product_id], name: :cart_items_user_product_unique_index, where: "user_id IS NOT NULL")
  end
end
