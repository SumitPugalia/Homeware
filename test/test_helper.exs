ExUnit.start()

# Mox setup for upload mocking
Mox.defmock(HomeWare.UploadMock, for: HomeWare.UploadBehaviour)
Application.put_env(:home_ware, :upload_impl, HomeWare.UploadMock)

Ecto.Adapters.SQL.Sandbox.mode(HomeWare.Repo, :manual)
