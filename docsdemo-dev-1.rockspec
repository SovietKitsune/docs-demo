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
   "markdown",
   "etlua",
   "dkjson",
   "luafilesystem"
}
build = {
   type = "builtin",
   modules = {
      docgen = "docgen.lua"
   }
}
