# Essentia

This is a hobby project I'm building to control a NuVo Essentia E6D series audio
distribution amplifier using Elixir.

Things I'm using or intending to use:

* [Nerves and Nerves-UART](//github.com/nerves-project) for communicating with the
  amp.
* [Scenic](//github.com/boydm/scenic) for a touchscreen UI
* [Phoenix](//github.com/phoenixframework) for web-based/smartphone interaction

Intended deployment:

* Raspberry PI (probably zero) with USB-to-DB9-Serial connector
* Raspberry PI3 with 7" touchscreen
