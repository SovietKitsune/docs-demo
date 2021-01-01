---@alias raw raw.module[]

---@class raw.module
---@field public filename string
---@field public classes raw.class[]
---@field public functions raw.function[]
---@field public data raw.data[]
---@field public name string
---@field public is_class_mod boolean
---@field public short_desc string
---@field public desc string
---@field public usage string

---@class raw.class
---@field public name string
---@field public name_in_source string
---@field public methods raw.function[]
---@field public desc string
---@field public short_desc string
---@field public usage string
---@field public inherits_from string[]
---@field public fields raw.field[]

---@class raw.function
---@field public name string
---@field public short_desc string
---@field public desc string
---@field public params raw.param[]
---@field public returns raw.return[]
---@field public usage string
---@field public is_virtual boolean
---@field public is_abstract boolean
---@field public is_deprecated boolean
---@field public is_static boolean
---@field public visibility raw.visibility

---@class raw.param
---@field public name string
---@field public desc string
---@field public type raw.type
---@field public is_opt boolean
---@field public default_value string

---@class raw.return
---@field public desc string
---@field public type raw.type

---@class raw.type
---@field public id raw.type.ids
---@field public type raw.type | nil Only exists on arrays, the type of the data within
---@field public name string | nil Only exists on custom types, the name of the custom type
---@field public key_type raw.type | nil Only exists on dicts, the type of the keys
---@field public value_type raw.type | nil Only exists on dicts, the type of the values
---@field public arg_types raw.types[] | nil Only exists on callables, the types of the arguments
---@field public arg_names string[] | nil Only exists on callables, the name of the arguments
---@field public return_types raw.types[] | nil Only exists on callables, the types of the return values
---@field public types raw.type[] | nil Only exists on ors, the types that could be described

---@class raw.field
---@field public name string
---@field public desc string
---@field public type raw.type
---@field public visibility raw.visibility

---@class raw.data
---@field public value raw.data.value

---@class raw.data.value
---@field public name string
---@field public short_desc string
---@field public desc string
---@field public visibility raw.visibility
---@field public constant boolean
---@field public type raw.type
---@field public value any

---@alias raw.visibility string
---| "'public'"
---| "'protected'"
---| "'private'"

---@alias raw.type.ids string
---| "'nil'"
---| "'boolean'"
---| "'number'"
---| "'string'"
---| "'function'"
---| "'userdata'"
---| "'thread'"
---| "'table'"
---| "'any'"
---| "'array'"
---| "'custom'"
---| "'dict'"
---| "'or'"
---| "'callable'"

---@class config
---@field public project config.project
---@field public cleaning config.cleaning

---@class config.project
---@field public readme string
---@field public template string
---@field public output string
---@field public topics string

---@class config.cleaning
---@field public forceRemove string[]