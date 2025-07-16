defmodule HomeWare.Repo.Migrations.CreateWishlistItems do
  use Ecto.Migration

  def change do
    create table(:wishlist_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :product_id, references(:products, on_delete: :delete_all, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:wishlist_items, [:user_id])
    create index(:wishlist_items, [:product_id])

    create unique_index(:wishlist_items, [:user_id, :product_id],
             name: :wishlist_items_user_product_unique_index
           )
  end
end
