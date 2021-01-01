# Docs demo

Experimental documentation generator alternative for [py-lua-doc](https://github.com/boolangery/py-lua-doc).

## Instructions

First, replace `docs.json` with whatever json file [py-lua-doc](https://github.com/boolangery/py-lua-doc) generated.

Next replace the `config.toml` with what your project is.

```toml
[project]
readme = "readme.md" # The index page
template = "./templates/markdown.etlua" # The template to use
output = "./docs" # Where to output the markdown
# topics = "./topics" # Extra markdown to add

[cleaning]
forceRemove = [ # If any sort of object contains these name, it is removed
   "get",
   "mt"
]
```

## TODO

* [x] Topics
* [x] Default parsing
* [x] Cleaner documentation output
* [x] Toml project configuration
* [ ] Bundle [py-lua-doc](https://github.com/boolangery/py-lua-doc)
* [ ] ~~Generate index.html~~ N/A, using markdown
* [ ] View source button
* [x] Fix functions which return multiple values

## Motivation

Sphinx uses Restructured text while text editors use markdown for viewing docs. You see the issue.