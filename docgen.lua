local markdown = require 'markdown'

local etlua = require 'etlua'
local json = require 'dkjson'

local lfs = require 'lfs'

local rawData

do
   local f = io.open('docs.json')
   rawData = json.decode(f:read('*a'))
   f:close()
end

local template

do
   local f = io.open('template.etlua')
   template = f:read('*a')
   f:close()
end

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

local filter = {}

local out = project.output

local function md(text)
   -- text = markdown(text)

   text = text:gsub('```(.-)\n(.-)```', function(lang, code)
      return '<pre><code class="' .. lang .. '">' .. code .. '</code></pre>'
   end)

   return markdown(text)
end

local function isBlank(file)
   return (
      file.short_desc == "" and
      file.desc == "" and
      file.usage == "" and
      #file.data == 0 and
      #file.classes == 0 and
      #file.functions == 0
   )
end

local function isUnwanted(obj)
   if not project.inferUnwanted then
      return false
   end

   return obj.name_in_source == ''
end

local function isStructure(obj)
   if obj.short_desc:sub(0, 6):lower() == 'struct' then
      return true
   end
end

local function typeResolver(obj)
   local str = ""

   if obj.id == 'or' then
      local tbl = {}

      for _, v in pairs(obj.types) do
         table.insert(tbl, typeResolver(v))
      end

      return table.concat(tbl, ' or ')
   elseif obj.id == 'dict' then
      return 'table<' ..
         typeResolver(obj.key_type) .. ', ' ..
         typeResolver(obj.value_type) .. '>'
   elseif obj.id == 'array' then
      return typeResolver(obj.type) .. '[]'
   elseif obj.id == 'custom' then
      return obj.name
   else
      return obj.id
   end
end

local function genParams(func)
   ---@language Html 
   local code = [[
      <table class="table">
         <thead class="thead-dark">
            <tr>
               <th scope="col">Parameter</th>
               <th scope="col">Type</th>
               <th scope="col">Optional</th>
               <th scope="col">Default</th>
               <th scope="col">Description</th>
            </tr>
         </thead>
         <tbody>
            %s
         </tbody>
      </table>
   ]]

   ---@language html 
   local paramTemplate = [[
      <tr>
         <td>%s</td>
         <td>%s</td>
         <td>%s</td>
         <td>%s</td>
         <td>%s</td>
      </tr>
   ]]

   local luaTypes = {
      ['nil'] = 'https://www.lua.org/pil/2.1.html',
      ['boolean'] = 'https://www.lua.org/pil/2.2.html',
      ['number'] = 'https://www.lua.org/pil/2.3.html',
      ['string'] = 'https://www.lua.org/pil/2.4.html',
      ['table'] = 'https://www.lua.org/pil/2.5.html',
      ['function'] = 'https://www.lua.org/pil/2.6.html',
      ['thread'] = 'https://www.lua.org/pil/2.7.html',
      ['userdata'] = 'https://www.lua.org/pil/2.7.html'
   }

   local check = '<i class="fas fa-check"></i>'
   local x = '<i class="fas fa-times"></i>'

   local params = ""

   for _, v in pairs(func.params) do
      local paramName = v.name

      local type = typeResolver(v.type)

      if paramName == '...' then
         type = type .. '...'
      end

      local optional = x

      --- TODO; add urls
      if type:match('or nil') or v.is_opt then
         optional = check
      end

      --- TODO; default
      local default = 'none'

      local description = v.desc == '' and 'none' or ''

      params = params .. paramTemplate:format(paramName, type, optional, default, description) .. '\n'
   end

   return code:format(params)
end

local function constructorParams(func)
   local params = ""

   for i, v in pairs(func.params) do
      local paramName = v.name

      local type = typeResolver(v.type)

      local optional = false

      local placed = false

      if type:match('or nil') or v.is_opt then
         optional = true
      end

      if optional and not params:match('%[') then
         params = params .. ' [, '
         placed = true
      end

      params = params .. (i ~= 1 and not placed and ', ' or '') .. paramName

      if optional and not params:match('%]') and i == #func.params then
         params = params .. ']'
      end
   end

   return params
end

local function paramTable(class)
   local out = ''

   local toLoop
   local other
   local name

   if #class.methods >= #class.fields then
      toLoop = class.methods
      other = class.fields

      name = 'methods'
   else
      toLoop = class.fields
      other = class.methods

      name = 'fields'
   end

   for i, v in pairs(toLoop) do
      local otherField = other[i]

      local paramsInsert = (name == 'fields' and v.name) or (otherField and otherField.name) or ''
      local methodInsert = (name == 'methods' and v.name) or (otherField and otherField.name) or ''

      paramsInsert = '<td>'  .. paramsInsert .. '</td>'
      methodInsert = '<td>' .. methodInsert .. '</td>'

      out = out .. '<tr>' .. (#class.fields > 1 and paramsInsert or '') .. '\n' .. (#class.methods > 1 and methodInsert or '') .. '\n' .. '</tr>' .. '\n'
   end

   return out
end

for _, file in pairs(rawData) do
   if not isBlank(file) then

   -- Filter out classes and group files with data or functions as modules

      for _, class in pairs(file.classes) do
         class.type = 'class'
         class.location = '../classes/' .. class.name .. '.html'

         class.short_desc = md(class.short_desc)
         class.desc = md(class.desc)

         if not isUnwanted(class) and not isStructure(class) then
            table.insert(project.classes, class)
         end

         if isStructure(class) then
            class.type = 'structure'
            class.location = '../structures/' .. class.name .. '.html'
            class.short_desc = md(class.short_desc:sub(7, #class.short_desc))
            table.insert(project.structures, class)
         end
      end

      -- Classes, modules same thing? Thats what Lua thinks at least

      if #file.data > 0 or #file.functions > 0 then
         local classMod = {}

         classMod.name = file.name
         classMod.type = 'module'
         classMod.short_desc = md(file.short_desc)
         classMod.desc = md(file.desc)
         classMod.location = '../modules/' ..file.name .. '.html'
         classMod.methods = file.functions
         classMod.fields = file.data

         table.insert(project.modules, classMod) -- sure it might be stored and said differently but they are the same thing lel
      end
   end
end

template = assert(etlua.compile(template))

if not lfs.attributes(out) then
   lfs.mkdir(out)
end

local sections = {
   'classes',
   'modules',
   'structures'
}

for _, v in pairs(sections) do
   print('Documenting ' .. v)

   if not lfs.attributes(out .. '/' .. v) then
      lfs.mkdir(out .. '/' .. v)
   end

   for _, current in pairs(project[v]) do
      local templateOut = template({
         project = project,
         current = current,
         genParams = genParams,
         constructorParams = constructorParams,
         paramTable = paramTable,
         typeResolver = typeResolver,
         md = md
      })

      do
         local f = io.open(out .. '/' .. v .. '/' .. current.name .. '.html', 'w+')
         f:write(templateOut)
         f:close()
      end
   end
end
