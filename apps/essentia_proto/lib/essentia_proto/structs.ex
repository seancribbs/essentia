defmodule EssentiaProto.ZoneStatus do
  defstruct [:id, :power, :source, :group, :volume, :party]
end

defmodule EssentiaProto.ZoneSetStatus do
  defstruct [:id, :override, :bass, :treble, :group, :volume_reset]
end
