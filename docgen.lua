--; TODO rewrite

local etlua = require 'etlua'
local json = require 'dkjson'
local toml = require 'toml'
local lfs = require 'lfs'

---@type raw
local docs

do
   local f = io.open('docs.json', 'r')

   docs = json.decode(f:read('*a'))

   f:close()
end

---@type config
local config

do
   local f = io.open('config.toml', 'r')

   local rawConfig = assert(toml.parse(f:read('*a')))

   f:close()

   rawConfig.project = rawConfig.project or {}

   rawConfig.cleaning = rawConfig.cleaning or {}

   rawConfig.cleaning.forceRemove = rawConfig.cleaning.forceRemove or {}

   config = rawConfig
end

local cleaned = {
   classes = {},
   modules = {}, -- Modules are composed of **only** functions and values, classes are kept separate
   structures = {},
   locations = {} -- name = category
}

local function tblSearch(tbl, v)
   for i = 1, #tbl do
      if tbl[i] == v then
         return tbl[i]
      end
   end

   return nil
end

---@param thing raw.module | raw.class
local function isUnwanted(thing)
   if tblSearch(config.cleaning.forceRemove, thing.name) then
      return true
   end

   if thing.functions then
      return thing.short_desc == '' and
         #thing.functions == 0 and
         #thing.data == 0
   else
      return thing.short_desc == '' and
         #thing.methods == 0 and
         #thing.fields == 0
   end
end

---@param mod raw.module
local function isModule(mod)
   -- A module is determined if
   -- 1. the module is a classmod
   -- 2. a class description starts with `module`
   -- 3. the module doesn't have any classes

   local isMod = mod.is_class_mod or
      #mod.classes == 0

   if isMod then
      return 'mod', mod
   else
      local mods = {}

      for i = 1, #mod.classes do
         local class = mod.classes[i]

         if class.short_desc:match('^%s*module') then
            table.insert(mods, {i, class, class.short_desc:gsub('^%s*module%s*', '')})
         end
      end

      return 'class', mods
   end
end

---@param class raw.class
local function isStructure(class)
   -- struct This describes...
   local isStruct = class.short_desc:match('^%s*struct') and true or false

   return isStruct, isStruct and class.short_desc:gsub('^%s*struct%s*', '') or nil
end

local function hasNil(rawType)
   if rawType.id == 'nil' then
      return true
   elseif rawType.id == 'or' then
      for i = 1, #rawType.types do
         if hasNil(rawType.types[i]) then
            return true
         end
      end
   end

   return false
end

---@param rawType raw.type
local function toHumanType(rawType)
   if rawType.id == 'array' then
      return toHumanType(rawType.type) .. '[]'
   elseif rawType.id == 'dict' then
      return 'table<' .. toHumanType(rawType.key_type) .. ', ' .. toHumanType(rawType.value_type) .. '>'
   elseif rawType.id == 'or' then
      local res = ''
      local has = hasNil(rawType)

      for i = 1, #rawType.types do
         if rawType.types[i].id ~= 'nil' then
            res = res .. (res ~= '' and ' | ' or '') .. toHumanType(rawType.types[i]) .. (has and '?' or '')
         end
      end

      return res
   elseif rawType.id == 'custom' then
      return rawType.name
   elseif rawType.id == 'callable' then
      local res = ''

      for i = 1, #rawType.arg_types do
         res = res .. (res ~= '' and ', ' or '') .. (rawType.arg_names[i] and rawType.arg_names[i] .. ': ' or '') .. toHumanType(rawType.arg_types[i])
      end

      local returnType = ''

      for k = 1, #rawType.return_types do
         returnType = returnType .. (returnType ~= '' and ', ' or ': ') .. toHumanType(rawType.return_types[k])
      end

      return 'function(' .. res .. ')' .. returnType
   else
      return rawType.id
   end
end

for i = 1, #docs do
   ---@type raw.module
   local mod = docs[i]

   -- Filter modules

   local modType, mods = isModule(mod)

   if modType == 'mod' then
      if not isUnwanted(mod) then
         cleaned.locations[mods.name] = 'modules'
         table.insert(cleaned.modules, mods)
      end

      goto continue
   else
      for k = 1, #mods do
         local pos = mods[k][1]

         table.remove(mod.classes, pos)

         if not isUnwanted(mods[k][2]) then
            cleaned.locations[mods[k][2].name] = 'modules'
            mods[k][2].short_desc = mods[k][3]
            table.insert(cleaned.modules, mods[k][2])
         end
      end
   end

   --- Filter classes and structures apart

   for k = 1, #mod.classes do
      local class = mod.classes[k]
      local isStruct, newDesc = isStructure(class)

      if isStruct then
         if not isUnwanted(class) then
            class.short_desc = newDesc -- Description might be just struct, stucts have no methods or data meaning they could be removed as unwanted
            cleaned.locations[class.name] = 'structures'
            table.insert(cleaned.structures, class)
         end
      else
         if not isUnwanted(class) then
            cleaned.locations[class.name] = 'classes'
            table.insert(cleaned.classes, class)
         end
      end
   end

   ::continue::
end

local out = config.project.output or './docs'

local template

do
   local f = assert(io.open(config.project.template or 'template.etlua', 'r'))

   local contents = f:read('*a')

   -- local parser = etlua.Parser()

   -- print(parser:compile_to_lua(contents))

   template = assert(etlua.compile(contents))

   f:close()
end

-- Create out directory

if not lfs.attributes(out) then
   lfs.mkdir(out)
end

-- Copy readme file

if config.project.readme then
   local f = assert(io.open(config.project.readme, 'r'))

   local contents = f:read('*a')

   f:close()

   local newLocation = assert(io.open(out .. '/index.md', 'w'))

   newLocation:write(contents)

   newLocation:close()
end

for i, section in pairs(cleaned) do
   if i ~= 'locations' then
      print('-- ' .. i .. ' --')

      if not lfs.attributes(out .. '/' .. i) then
         lfs.mkdir(out .. '/' .. i)
      end

      for mod = 1, #section do
         local name = section[mod].name
         print('- ' .. section[mod].name .. ' -')

         local f = assert(io.open(out .. '/' .. i .. '/' .. name .. '.md', 'w'))

         f:write(template {
            currentModule = section[mod],
            currentSection = i,
            parseType = toHumanType,
            locations = cleaned.locations,
            cleaned = cleaned,
            p = p
         })

         f:close()
      end
   end
end

if config.project.topics then
   if not lfs.attributes(out .. '/topics') then
      lfs.mkdir(out .. '/topics')
   end

   for file in lfs.dir(config.project.topics) do
      if file ~= '.' or file ~= '..' then
         local f = assert(io.open(config.project.topics .. '/' .. file, 'r'))

         local contents = f:read('*a')
         f:close()

         local newLocation = assert(io.open(out .. '/topics/' .. file, 'w'))

         newLocation:write(contents)

         newLocation:close()
      end
   end
end