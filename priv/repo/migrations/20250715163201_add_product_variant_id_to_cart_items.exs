defmodule HomeWare.Repo.Migrations.AddProductVariantIdToCartItems do
  use Ecto.Migration

  def change do
    alter table(:cart_items) do
      add :product_variant_id, references(:product_variants, on_delete: :delete_all, type: :uuid)
    end
  end
end
