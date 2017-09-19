defmodule ScpToAnywhere.Destination do
  @moduledoc """
  Defines the behaviour for file destinations, i.e. Slack

  All *file* functions are for single file transfers via SCP.
  Currently unimplemented, but for SCPing directories, we will
  add *dir* functions to support that, along with a callback that
  checks if this destination can support directory transfers
  """

  @doc """
  Start a transfer of a single file.

  Returns `{:ok, term}` if successful or {:error, term} if there was a failure.

  `term` in `{:error, term}` should be the reason for failure.

  `term` in {:ok, term} should be some reference or pid that the scp process
  will then put as the first arugment of the rest of the xfer functions
  for this behaviour. Basically some identifier. For hackney based destinations
  like slack, this would be the ClientRef we get back from hackney when starting a
  request.

  First argument is the user who is sending a file.
  Second argument is the "destination" string (i.e. the channel for slack).
  Third argument is the name of the file.
  """
  @callback start_file_xfer(String.t, String.t, String.t) :: {:ok, term} | {:error, term}

  @doc """
  Sends a file part as it comes in from SCP
  """
  @callback file_xfer_part(term, binary) :: :ok | {:error, term}

  @doc """
  Sends the last file part.
  """
  @callback finish_file_xfer(term, binary) :: :ok | {:error, term}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour ScpToAnywhere.Destination
    end
  end
end
