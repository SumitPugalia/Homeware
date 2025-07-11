defmodule HomeWare.Repo.Migrations.CreateProductReviews do
  use Ecto.Migration

  def change do
    create table(:product_reviews) do
      add :rating, :integer, null: false
      add :title, :string
      add :comment, :text
      add :status, :string, default: "pending", null: false
      add :is_verified_purchase, :boolean, default: false, null: false
      add :helpful_votes, :integer, default: 0, null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :order_id, references(:orders, on_delete: :nilify_all)

      timestamps()
    end

    create index(:product_reviews, [:product_id])
    create index(:product_reviews, [:user_id])
    create index(:product_reviews, [:status])
    create index(:product_reviews, [:rating])
    create unique_index(:product_reviews, [:user_id, :product_id], name: :product_reviews_user_product_unique_index)
  end
end
