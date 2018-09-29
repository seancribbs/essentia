defmodule EssentiaProto.Commands do
  @moduledoc "High-level commands to the E6D, based on documentation from NuVo."
  import EssentiaProto.Control, only: [command: 2, command: 3]
  alias EssentiaProto.{ZoneStatus, ZoneSetStatus}
  ###### GUARDS AND UTILITY FUNCTIONS

  defguardp is_source(n) when n in 1..6
  defguardp is_freq(f) when f in [38, 56]
  defguardp is_zone(z) when z in 1..12

  defp zonestr(z) when is_zone(z) and z < 10, do: "0#{z}"
  defp zonestr(z) when is_zone(z), do: "#{z}"

  ###### NON-VOLATILE COMMANDS

  @doc "Reads status of SOURCE IR carrier frequency settings. Values are in kHz."
  def source_ir_status() do
    command("IRSETSR", "IRSET:", &parse_source_ir_status/1)
  end

  @doc "Restores DEFAULT SOURCE IR carrier frequency settings (38 kHz for all six sources)"
  def reset_source_ir() do
    command("IRSETDF", "IRSET:", &parse_source_ir_status/1)
  end

  @doc "Sets SOURCE `x` to `f` kHz IR repeat carrier (only 38 or 56 are valid frequencies)"
  def set_source_ir(x, f) when is_source(x) and is_freq(f) do
    command("S#{x}IR#{f}SET", "IRSET:", &parse_source_ir_status/1)
  end

  ###### NORMAL COMMANDS

  @doc "Connect STATUS REQUEST"
  def get_zone_status(z) when is_zone(z) do
    str = zonestr(z)
    command("Z#{str}CONSR", "Z#{str}", &parse_zone_status(z, &1))
  end

  @doc "ZoneSet STATUS REQUEST"
  def get_zoneset_status(z) when is_zone(z) do
    str = zonestr(z)
    command("Z#{str}SETSR", "Z#{str}", &parse_zoneset_status(z, &1))
  end

  @doc "Turn zone ON"
  def zone_on(z) when is_zone(z) do
    str = zoneset(z)
    command("Z#{str}ON", "Z#{str}", &parse_zone_status(z, &1))
  end

  @doc "Turn zone OFF"
  def zone_off(z) when is_zone(z) do
    str = zoneset(z)
    command("Z#{str}OFF", "Z#{str}", &parse_zone_status(z, &1))
  end

  @doc "Turn ALL zones OFF"
  def all_off() do
    command("ALLOFF", "ALLOFF", &parse_confirmation/1)
  end

  @doc "Firmware version query"
  def version() do
    command("VER", "NUVO_E6D_")
  end

  ###### RESPONSE PARSERS

  # Parser for empty confirmation responses
  defp parse_confirmation(_) do
    :success
  end

  # Parser for IRSET responses
  defp parse_source_ir_status(str) do
    str
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
  end

  # Parser for zone status responses
  def parse_zone_status(id, str) do
    [
      "PWR" <> power,
      "SRC" <> source,
      "GRP" <> group,
      "VOL" <> volume,
      "P" <> party
    ] = String.split(str, ",")

    %ZoneStatus{
      id: id,
      power: flag(power, "ON"),
      source: String.to_integer(source),
      group: flag(group, "0"),
      volume:
        case volume do
          "MT" -> :mute
          "XM" -> :external_mute
          _ -> String.to_integer(volume)
        end,
      party:
        case party do
          "MST" -> :controller
          "SLV" -> :passive
          "OFF" -> :local
        end
    }
  end

  def parse_zoneset_status(id, str) do
    [
      "OR" <> override,
      "BASS" <> bass,
      "TREB" <> treble,
      "GRP" <> source_group,
      "VRST" <> volume_reset
    ] = String.split(str, ",")

    %ZoneSetStatus{
      id: id,
      override: flag(override, "1"),
      bass: String.to_integer(bass),
      treble: String.to_integer(treble),
      group: flag(source_group, "0"),
      volume_reset: flag(volume_reset, "0")
    }
  end

  defp flag(v, v), do: :on
  defp flag(_, _), do: :off
end
