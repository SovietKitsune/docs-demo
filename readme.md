# Docs demo

Experimental documentation generator alternative for [py-lua-doc](https://github.com/boolangery/py-lua-doc).

## Instructions

First, replace `docs.json` with whatever json file [py-lua-doc](https://github.com/boolangery/py-lua-doc) generated.

Next replace the project info with what your project is.

```lua
local project = {
   name = 'typed',
   source = 'https://github.com/SovietKitsune/typed',
   output = './docs',
   inferUnwanted = true,
   topics = {},
   classes = {},
   modules = {},
   structures = {}
}
```

You would want to replace `name` and `source` fields. You could also change `output` if you want. Changing `inferUnwanted` to false is not recommended as it will include things like examples into the documentation and try to parse them as modules instead of examples.

## TODO

* Topics
* Default parsing
* Cleaner documentation output
* Toml project configuration
* Bundle [py-lua-doc](https://github.com/boolangery/py-lua-doc)

## Motivation

Sphinx uses Restructured text while text editors use markdown for viewing docs. You see the issue.