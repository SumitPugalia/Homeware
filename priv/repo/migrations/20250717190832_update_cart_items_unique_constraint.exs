defmodule HomeWare.Repo.Migrations.UpdateCartItemsUniqueConstraint do
  use Ecto.Migration

  def change do
    # Drop the old unique constraint if it exists
    execute "DROP INDEX IF EXISTS cart_items_user_product_unique_index"

    # Create new unique constraint that includes product_variant_id
    create unique_index(:cart_items, [:user_id, :product_id, :product_variant_id],
             name: :cart_items_user_product_variant_unique_index,
             where: "user_id IS NOT NULL"
           )
  end
end
