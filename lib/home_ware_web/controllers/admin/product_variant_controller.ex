defmodule HomeWareWeb.Admin.ProductVariantController do
  use HomeWareWeb, :admin_controller
  import Phoenix.Component, only: [to_form: 1]
  alias HomeWare.Products
  alias HomeWare.Products.Product
  alias HomeWare.Products.ProductVariant

  def new(conn, %{"product_id" => product_id}) do
    product = Products.get_product!(product_id)
    changeset = ProductVariant.changeset(%ProductVariant{product_id: product.id}, %{})
    form = to_form(changeset)
    render(conn, "new.html", product: product, form: form)
  end

  def create(conn, %{"product_id" => product_id, "product_variant" => variant_params}) do
    product = Products.get_product!(product_id)
    variant_params = Map.put(variant_params, "product_id", product_id)

    case Products.create_product_variant(variant_params) do
      {:ok, _variant} ->
        conn
        |> put_flash(:info, "Variant created!")
        |> redirect(to: ~p"/admin/products/#{product_id}/edit")

      {:error, changeset} ->
        form = to_form(changeset)
        render(conn, "new.html", product: product, form: form)
    end
  end

  def edit(conn, %{"product_id" => product_id, "id" => id}) do
    product = Products.get_product!(product_id)
    variant = Products.get_product_variant!(id)
    changeset = ProductVariant.changeset(variant, %{})
    form = to_form(changeset)
    render(conn, "edit.html", product: product, variant: variant, form: form)
  end

  def update(conn, %{"product_id" => product_id, "id" => id, "product_variant" => variant_params}) do
    product = Products.get_product!(product_id)
    variant = Products.get_product_variant!(id)

    case Products.update_product_variant(variant, variant_params) do
      {:ok, _variant} ->
        conn
        |> put_flash(:info, "Variant updated!")
        |> redirect(to: ~p"/admin/products/#{product_id}/edit")

      {:error, changeset} ->
        form = to_form(changeset)
        render(conn, "edit.html", product: product, variant: variant, form: form)
    end
  end

  def delete(conn, %{"product_id" => product_id, "id" => id}) do
    variant = Products.get_product_variant!(id)
    {:ok, _} = Products.delete_product_variant(variant)

    conn
    |> put_flash(:info, "Variant deleted!")
    |> redirect(to: ~p"/admin/products/#{product_id}/edit")
  end
end
