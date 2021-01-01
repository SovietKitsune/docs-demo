package = "docsDemo"
version = "dev-1"
source = {
   url = "git://github.com/SovietKitsune/docsDemo"
}
description = {
   homepage = "https://github.com/SovietKitsune/docsDemo",
   license = "MIT"
}
dependencies = {
   "etlua",
   "dkjson",
   "luafilesystem",
   "lua-toml"
}
build = {
   type = "builtin",
   modules = {
      ['docgen'] = 'docgen.lua'
   },
   install = {
      bin = {
         ['py-lua-doc'] = 'bin/docgen'
      }
   }
}
