defmodule HomeWare.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :image_url, :string
    field :is_active, :boolean, default: true

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :products, HomeWare.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :description, :image_url, :parent_id, :is_active])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
