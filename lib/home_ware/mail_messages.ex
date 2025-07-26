defmodule HomeWare.MailMessages do
  @moduledoc """
  The MailMessages context for handling contact form messages.
  """
  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.MailMessage

  def list_mail_messages do
    MailMessage
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
  end

  def get_mail_message!(id), do: Repo.get!(MailMessage, id)

  def create_mail_message(attrs \\ %{}) do
    %MailMessage{}
    |> MailMessage.changeset(attrs)
    |> Repo.insert()
  end

  def update_mail_message(%MailMessage{} = mail_message, attrs) do
    mail_message
    |> MailMessage.changeset(attrs)
    |> Repo.update()
  end

  def delete_mail_message(%MailMessage{} = mail_message) do
    Repo.delete(mail_message)
  end

  def change_mail_message(%MailMessage{} = mail_message, attrs \\ %{}) do
    MailMessage.changeset(mail_message, attrs)
  end
end
