defmodule HomeWare.ProductReview do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @review_statuses ~w(pending approved rejected)a

  schema "product_reviews" do
    field :rating, :integer
    field :title, :string
    field :comment, :string
    field :status, Ecto.Enum, values: @review_statuses, default: :pending
    field :is_verified_purchase, :boolean, default: false
    field :helpful_votes, :integer, default: 0

    belongs_to :user, HomeWare.Accounts.User
    belongs_to :product, HomeWare.Products.Product
    belongs_to :order, HomeWare.Orders.Order

    timestamps(type: :utc_datetime)
  end

  def changeset(product_review, attrs) do
    product_review
    |> cast(attrs, [
      :rating,
      :title,
      :comment,
      :status,
      :is_verified_purchase,
      :helpful_votes,
      :user_id,
      :product_id,
      :order_id
    ])
    |> validate_required([:rating, :title, :comment, :user_id, :product_id])
    |> validate_number(:rating, greater_than: 0, less_than_or_equal_to: 5)
    |> validate_length(:title, min: 3, max: 100)
    |> validate_length(:comment, min: 10, max: 1000)
    |> validate_inclusion(:status, @review_statuses)
  end
end
