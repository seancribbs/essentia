defmodule EssentiaProto.Control do
  @moduledoc "Direct, low-level command interface to the E6D"
  # Registered name for the pid
  @uart EssentiaProto.UART
  import Nerves.UART, only: [open: 3, write: 2]

  # Might need to tweak these in the app env?
  @command_timeout 1000
  @power_on_timeout 4000

  def initialize(tty) do
    options = Application.get_env(:essentia_proto, :uart_options)

    with :ok <- open(@uart, tty, options) do
      drain_power_on_garbage(tty)
    end
  end

  def command(command, response, parser \\ (& &1)) when is_binary(command) and is_binary(response) do
    # Assumes active: true
    write(@uart, "*#{command}")
    :ok = drain(@uart)

    receive do
      # We got the response we expected
      {:nerves_uart, _tty, "#" <> ^response <> rest} ->
        {:ok, parser.(rest)}

      # If a command has an error in it (does not adhere to exact command
      # syntax), the E6D will respond with a "#?<CR>" string.
      {:nerves_uart, _tty, "#?"} ->
        {:error, :bad_command}

      # Something went wrong with the serial port
      {:nerves_uart, _tty, {:error, _} = err} ->
        err

      # We got something we didn't expect
      {:nerves_uart, _tty, other} ->
        {:error, {:unexpected_reply, other}}
    after
      @command_timeout ->
        {:error, :timeout}
    end
  end

  defp drain_power_on_garbage(tty) do
    # For the first four seconds after power-on, a series of non-control related
    # characters will be issued at a wide range of baud rates. These are
    # necessary queries to a program that may be running on a connected PC for
    # the purpose of Firmware field upgrades. They sohuld be ignored by the host
    # control system.
    receive do
      {:nerves_uart, ^tty, bin} when is_binary(bin) ->
        drain_power_on_garbage(tty)

      {:nerves_uart, ^tty, err} ->
        err
    after
      @power_on_timeout ->
        :ok
    end
  end
end
