defmodule ScpToAnywhere do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:scp_to_anywhere, :port)
    :ssh.daemon(port, [system_dir: './ssh',
                       ssh_cli: {ScpToAnywhere.SCP, []},
                       subsystems: [],
                       key_cb: ScpToAnywhere.Key,
                       pwdfun: &ScpToAnywhere.Password.auth/4,
                       preferred_algorithms: [public_key: [:"ssh-rsa", :"ssh-dss"]]])
  end
end
