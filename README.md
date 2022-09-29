# CryPaint

A drawing program written in Crystal using ImgUi and SFML. Work in progress!

## Development

1. Install SFML (`sfml2-devel` on OpenSUSE, something similar on other distros)
2. `shards install`
3. `export LD_LIBRARY_PATH="$(pwd)/lib/imgui-sfml"` to make sure `libcimgui.so` is found
4. Start hacking

## Contributing

1. Fork it (<https://github.com/andriamanitra/crypaint/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
