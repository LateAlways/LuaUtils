--[[ 
  Usage: 
  local SerializeTable = require(path.to.TableSerializer)

  local Example: {any} = {...}
  local serialized = SerializeTable(Example)
]]--
function export(tabl, tabs)
    local function formatstring(str, stringchar)
        local stringchar = stringchar or "\""
        local function isnormalcharacter(char)
            local charbyte = string.byte(char)
            if charbyte >= 32 and charbyte <= 126 or char == 10 then
                return true
            else
                return false
            end
        end

        local function formatfunc(char)
            if isnormalcharacter(char) then
                if char == stringchar then
                    return table.concat({"\\", stringchar})
                else
                    if char == "\n" then
                        return "\\n"
                    else
                        return char
                    end
                end
            else
                return table.concat({"\\", tostring(string.byte(char))})
            end
        end

        return (str:gsub(".", formatfunc) or str)
    end

    if #tabl == 0 then return "{}" end
    tabs = tabs or 1
    local tab = string.rep(" ", tabs*4)
    local out = {"{"}
    for i,v in tabl do
        table.insert(out, "\n")
        if typeof(i) == "string" then
            table.insert(out, tab)
            table.insert(out, "[\"")
            table.insert(out, formatstring(i))
            table.insert(out, "\"] = ")
        elseif typeof(i) == "number" then
            table.insert(out, tab)
            table.insert(out, "[")
            table.insert(out, tostring(i))
            table.insert(out, "] = ")
        else
            table.insert(out, tab)
            table.insert(out, "[\"")
            table.insert(out, formatstring(tostring(i)))
            table.insert(out, "(converted to string)\"] = ")
        end
        if typeof(v) == "string" then
            table.insert(out, "\"")
            table.insert(out, formatstring(v))
            table.insert(out, "\"")
        elseif typeof(v) == "number" then
            table.insert(out, tostring(v))
        elseif typeof(v) == "table" then
            table.insert(out, export(v, tabs + 1))
        elseif typeof(v) == "boolean" then
            table.insert(out, tostring(v))
        else
            table.insert(out, "\"")
            table.insert(out, formatstring(tostring(v)))
            table.insert(out, " (converted to string)\"")
        end
        table.insert(out, ",")
    end
    table.remove(out, #out)
    table.insert(out, "\n")
    table.insert(out, string.rep(" ", (tabs-1)*4))
    table.insert(out, "}")
    return table.concat(out)
end
return function(tabl) return export(tabl) end
