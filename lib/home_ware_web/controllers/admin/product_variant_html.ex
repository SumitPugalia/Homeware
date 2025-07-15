defmodule HomeWareWeb.Admin.ProductVariantHTML do
  use HomeWareWeb, :html

  import HomeWareWeb.Admin.Shared, only: [render_admin_sidebar: 1]

  embed_templates "product_variant/*"
end
