use Mix.Config

config :scp_to_anywhere,
  slack_token: "",
  users: [{"username", "password or :false for no password", "ssh public key"}]

