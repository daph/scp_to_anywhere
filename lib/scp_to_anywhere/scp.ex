defmodule ScpToAnywhere.SCP do
  @behaviour :ssh_daemon_channel
  require Logger

  defstruct name: "",
            length: 0,
            mode: 0000,
            file_dest: "",
            command: "",
            user: "",
            in_session: false,
            dclient: nil,
            dest: nil

  @type t :: %__MODULE__{
    name: String.t,
    length: integer,
    mode: integer,
    file_dest: String.t,
    command: String.t,
    user: String.t,
    in_session: boolean,
    dclient: term,
    dest: atom
  }

  def init([]) do
    {:ok, %__MODULE__{}}
  end

  def handle_msg({:ssh_channel_up, _chan_id, _conn_man}, _state) do
    {:ok, %__MODULE__{}}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:data, chan_id, 0, data}},
                     state=%{in_session: true, length: length})
  when length > 0 do
    Logger.debug("Getting data #{byte_size(data)}")
    data_size = byte_size(data)
    rest_length = length - data_size

    if rest_length <= 0 do
      # Ugly hack to remove the zero byte at the end of the data
      fixed_data_size = data_size - 1
      << fixed_data :: binary-size(fixed_data_size), _leftover :: binary >> = data
      state.dest.finish_file_xfer(state.dclient, fixed_data)
      Logger.info("Done with transfer of #{state.name}")
      :ssh_connection.send(cm, chan_id, <<0>>)
      {:ok, %__MODULE__{state | in_session: false}}
    else
      state.dest.file_xfer_part(state.dclient, data)
      {:ok, %__MODULE__{state | length: rest_length}}
    end
  end

  def handle_ssh_msg({:ssh_cm, cm, {:data, chan_id, 0, data}}, state=%__MODULE__{in_session: true}) do
    Logger.info("Got data: #{inspect data}")
    <<command :: binary-size(1), _ :: binary>> = data
    case command do
      "C" ->
        [<<_ :: 8, mode :: binary>>, length|file] = String.split(data)
        file = file |> Enum.join(" ")
        length = String.to_integer(length)
        file = String.trim(file)
        Logger.info("Create file #{file}, length of #{length}, with mode #{mode}")
        {:ok, dclient} = state.dest.start_file_xfer(state.user, state.file_dest, file)
        :ssh_connection.send(cm, chan_id, <<0>>)
        nstate =
          state
          |> Map.put(:length, length)
          |> Map.put(:name, file)
          |> Map.put(:dclient, dclient)
        {:ok, nstate}
      _ ->
        Logger.info("Other command #{inspect command}")
        Logger.info("Data: #{inspect data}")
        :ssh_connection.close(cm, chan_id)
        {:ok, state}
    end
  end

  def handle_ssh_msg({:ssh_cm, cm, {:eof, chan_id}}, state) do
    Logger.debug("Got eof")
    :ssh_connection.send(cm, chan_id, <<0>>)
    :ssh_connection.close(cm, chan_id)
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:exec, chan_id, true, cmd}}, state) do
    user =
      :ssh.connection_info(cm, [:user])
      |> Keyword.get(:user)
      |> to_string()
    Logger.info("Got exec: #{cmd} from user: #{user}")
    command =
      cmd
      |> to_string()
      |> String.split()
    case command do
      ["scp"|rest] ->
        :ssh_connection.send(cm, chan_id, <<0>>)
        file_dest = rest |> List.last()
        dest = get_destination(file_dest)
        nstate =
          state
          |> Map.put(:in_session, true)
          |> Map.put(:file_dest, file_dest)
          |> Map.put(:dest, dest)
          |> Map.put(:user, user)
        {:ok, nstate}
      _ ->
        :ssh_connection.send(cm, chan_id, "SCP ONLY\n")
        :ssh_connection.close(cm, chan_id)
        {:ok, state}
    end
  end

  def handle_ssh_msg(other, state) do
    Logger.info("Got unknown ssh msg: #{inspect other}")
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end


  defp get_destination(file_dest) do
    file_dest
    |> String.trim_leading("/")
    |> Path.split()
    |> List.first
    |> String.to_existing_atom()
    |> (&(Application.get_env(:scp_to_anywhere, :destinations) |> Keyword.get(&1))).()
  end
end
