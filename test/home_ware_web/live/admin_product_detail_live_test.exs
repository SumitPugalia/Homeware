defmodule HomeWareWeb.AdminProductDetailLiveTest do
  use HomeWareWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import HomeWare.Factory
  alias HomeWare.Products
  alias HomeWare.Guardian

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HomeWare.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HomeWare.Repo, {:shared, self()})
    end

    bypass = Bypass.open()
    user = HomeWare.Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    %{user: user, token: token, bypass: bypass}
  end

  defp log_in_user(conn, user, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> assign(:current_user, user)
  end

  setup [:create_product]

  defp create_product(_) do
    category = insert(:category)
    product = insert(:product, %{category_id: category.id})
    %{product: product}
  end

  describe "product details live" do
    setup [:create_product]

    test "renders product details and allows editing", %{
      conn: conn,
      user: user,
      token: token,
      product: product
    } do
      conn = log_in_user(conn, user, token)
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

    test "shows validation errors on invalid input", %{
      conn: conn,
      user: user,
      token: token,
      product: product
    } do
      conn = log_in_user(conn, user, token)
      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")
      form = form(lv, "#product-form", product: %{name: "", price: -1})
      html = render_change(form)
      assert html =~ "can't be blank"
      assert html =~ "must be greater than 0"
    end

    test "product details live deletes product and redirects", %{
      conn: conn,
      user: user,
      token: token,
      product: product
    } do
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products/#{product.id}")

      live |> element("button", "DELETE") |> render_click()

      # Should redirect to products list
      assert_redirect(live, "/admin/products")

      # Product should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Products.get_product!(product.id)
      end
    end

    test "cancel redirects to product list", %{
      conn: conn,
      user: user,
      token: token,
      product: product
    } do
      conn = log_in_user(conn, user, token)
      {:ok, lv, _html} = live(conn, "/admin/products/#{product.id}")
      render_click(element(lv, "button", "CANCEL"))
      assert_redirect(lv, "/admin/products")
    end

    test "uploads multiple images and updates product images", %{
      conn: conn,
      user: user,
      token: token,
      product: product,
      bypass: bypass
    } do
      conn = log_in_user(conn, user, token)

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
end
