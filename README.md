# CryPaint

A drawing program written in Crystal using [ImGui](https://github.com/ocornut/imgui) and [SFML](https://www.sfml-dev.org/). Work in progress!

## Development

1. Make sure you have [Crystal-lang](https://crystal-lang.org/) installed
2. Install [SFML](https://www.sfml-dev.org/) (`sfml2-devel` on OpenSUSE, something similar on other distros)
3. Install dependencies with `shards install`
4. Run `export LD_LIBRARY_PATH="$(pwd)/lib/imgui-sfml"` to make sure `libcimgui.so` is found
5. Run the program with `shards run` (or `shards build` to just compile)
6. Start hacking

## Contributing

1. Fork it (<https://github.com/andriamanitra/crypaint/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
