use Mix.Config

# SERIAL PORT PARAMETERS: RS232, RTS/CTS or software flow control (XON/XOFF) NOT
# required, 9600 baud, 8N1 protocol
config :essentia_proto, :uart_options,
  speed: 9600,
  data_bits: 8,
  parity: :none,
  stop_bits: 1,
  framing: {Nerves.UART.Framing.Line, separator: "\r"},
  active: true
