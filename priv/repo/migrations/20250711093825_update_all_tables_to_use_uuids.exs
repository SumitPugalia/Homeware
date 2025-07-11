defmodule HomeWare.Repo.Migrations.UpdateAllTablesToUseUuids do
  use Ecto.Migration

  def change do
    # Enable UUID extension
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""

    # Update users table
    alter table(:users) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
    end

    # Update categories table
    alter table(:categories) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :parent_id, references(:categories, type: :uuid, on_delete: :nothing)
    end

    # Update products table
    alter table(:products) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :category_id, references(:categories, type: :uuid, on_delete: :nothing)
    end

    # Update addresses table
    alter table(:addresses) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :user_id, references(:users, type: :uuid, on_delete: :delete_all)
    end

    # Update orders table
    alter table(:orders) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      modify :shipping_address_id, references(:addresses, type: :uuid, on_delete: :nothing)
      modify :billing_address_id, references(:addresses, type: :uuid, on_delete: :nothing)
    end

    # Update order_items table
    alter table(:order_items) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :order_id, references(:orders, type: :uuid, on_delete: :delete_all)
      modify :product_id, references(:products, type: :uuid, on_delete: :nothing)
    end

    # Update product_reviews table
    alter table(:product_reviews) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      modify :product_id, references(:products, type: :uuid, on_delete: :delete_all)
      modify :order_id, references(:orders, type: :uuid, on_delete: :nothing)
    end

    # Update cart_items table
    alter table(:cart_items) do
      modify :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      modify :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      modify :product_id, references(:products, type: :uuid, on_delete: :delete_all)
    end
  end
end
