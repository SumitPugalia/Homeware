defmodule HomeWare.MailMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mail_messages" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :subject, :string
    field :message, :string
    timestamps()
  end

  def changeset(mail_message, attrs) do
    mail_message
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :subject, :message])
    |> validate_required([:first_name, :last_name, :email, :subject, :message])
    |> validate_format(:email, ~r/@/)
  end
end
