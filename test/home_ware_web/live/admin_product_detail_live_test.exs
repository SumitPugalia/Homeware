defmodule HomeWareWeb.AdminProductDetailLiveTest do
  use HomeWareWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import HomeWare.Factory
  alias HomeWare.Products

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  setup [:register_and_log_in_admin, :create_product]

  defp register_and_log_in_admin(%{conn: conn}) do
    conn = Phoenix.ConnTest.init_test_session(conn, %{})
    conn = log_in_admin_user(conn)
    {:ok, conn: conn}
  end

  describe "product details live" do
    setup [:create_product]

    test "renders product details and allows editing", %{conn: conn, product: product} do
      {:ok, lv, html} = live(conn, "/admin/products/#{product.id}")
      assert html =~ product.name
      assert html =~ "Product Details"

      # Edit product name
      new_name = "Updated Product Name"

      form =
        form(lv, "#product-form",
          product: %{
            name: new_name,
            description: product.description,
            category_id: product.category_id,
            brand: product.brand,
            sku: product.sku,
            inventory_quantity: product.inventory_quantity,
            price: product.price,
            compare_at_price: product.compare_at_price
          }
        )

      render_change(form)
      render_submit(form)
      assert render(lv) =~ new_name
    end

    test "shows validation errors on invalid input", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")
      form = form(lv, "#product-form", product: %{name: "", price: -1})
      html = render_change(form)
      assert html =~ "can't be blank"
      assert html =~ "must be greater than 0"
    end

    test "deletes product and redirects", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")
      render_click(element(lv, "button", "DELETE"))
      assert_redirect(lv, "/admin/products")
      refute Products.get_product!(product.id)
    end

    test "cancel redirects to product list", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")
      render_click(element(lv, "button", "CANCEL"))
      assert_redirect(lv, "/admin/products")
    end

    test "uploads multiple images and updates product images", %{
      conn: conn,
      product: product,
      bypass: bypass
    } do
      Bypass.expect(bypass, "PUT", "/DO_SPACES_BUCKET/products/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")

      upload =
        file_input(lv, "#product-form", :images, [
          %{last_modified: 0, name: "test1.png", content: <<1, 2, 3>>, type: "image/png"},
          %{last_modified: 0, name: "test2.png", content: <<4, 5, 6>>, type: "image/png"}
        ])

      render_upload(upload, "test1.png")
      render_upload(upload, "test2.png")

      form =
        form(lv, "#product-form",
          product: %{
            name: product.name,
            description: product.description,
            category_id: product.category_id,
            brand: product.brand,
            sku: product.sku,
            inventory_quantity: product.inventory_quantity,
            price: product.price,
            compare_at_price: product.compare_at_price
          }
        )

      render_submit(form)
      updated = Products.get_product!(product.id)
      assert length(updated.images) >= 2
    end
  end

  defp create_product(_) do
    category = insert(:category)
    product = insert(:product, %{category_id: category.id})
    %{product: product}
  end
end
