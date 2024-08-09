--[[ 
  Usage: 
  local SerializeTable = require(path.to.TableSerializer)

  SerializeTable(Table: {any}, ForceDictionaryLayout: boolean?, Beautify: boolean?)
]]--

function export(tabl, forcedictlayout, beautify, tabs)
    local SPACES_PER_TAB = 2
    local loop
    local typeof = typeof or type
    if _VERSION == "Luau" then loop = function(a) return a end else loop = pairs end
    local function formatstring(str, stringchar)
        local stringchar = stringchar or "\""
        local function isnormalcharacter(char)
            local charbyte = string.byte(char)
            if charbyte >= 32 and charbyte <= 126 or charbyte == 10 then
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

    local IsArray = true
    local containsTable = false
    local completeIsArray = false
    local completeContainsTable = false
    local isEmpty = true
    if not forcedictlayout then
        local previous = 0
        for i,v in loop(tabl) do
            isEmpty = false
            if typeof(i) ~= "number" or i-previous ~= 1 then
                IsArray = false
                completeIsArray = true
            else
                previous = i
            end
            if typeof(v) == "table" then
                containsTable = true
                completeContainsTable = true
            end
            if completeIsArray and completeContainsTable then
                break
            end
        end
    else
        IsArray = false
        containsTable = false
        for _,_ in loop(tabl) do
            isEmpty = false
            break
        end
    end

    if isEmpty then return "{}" end
    
    if not IsArray and beautify == nil then beautify = true end

    tabs = tabs or 1
    local tab = string.rep(" ", tabs*SPACES_PER_TAB)
    local out = {"{"}
    for i,v in loop(tabl) do
        if (tabs == 1 or not IsArray or containsTable) and beautify then
            table.insert(out, "\n")
            table.insert(out, tab)
        end
        if forcedictlayout or not IsArray then
            table.insert(out, "[")
            if typeof(i) == "string" then
                if formatstring(i) == i and not forcedictlayout then
                    table.remove(out, #out)
                else
                    table.insert(out, "\"")
                end
                
                table.insert(out, formatstring(i))
                if formatstring(i) ~= i or forcedictlayout then
                    table.insert(out, "\"]")
                end
            elseif typeof(i) == "number" then
                table.insert(out, tostring(i))
                table.insert(out, "]")
            else
                table.insert(out, "\"")
                table.insert(out, formatstring(tostring(i)))
                table.insert(out, "(converted to string)\"]")
            end
            table.insert(out, " = ")
        end
        if typeof(v) == "string" then
            table.insert(out, "\"")
            table.insert(out, formatstring(v))
            table.insert(out, "\"")
        elseif typeof(v) == "number" then
            if tostring(v) == "inf" or tostring(v) == "1.#INF" then
                table.insert(out, "math.huge")
            elseif tostring(v) == "-inf" or tostring(v) == "-1.#INF" then
                table.insert(out, "-math.huge")
            elseif tostring(v) == "nan" or tostring(v) == "-1.#IND" then
                table.insert(out, "0/0")
            else
                table.insert(out, tostring(v))
            end
        elseif typeof(v) == "table" then
            table.insert(out, export(v, forcedictlayout, beautify, tabs + 1))
        elseif typeof(v) == "boolean" then
            table.insert(out, tostring(v))
        else
            table.insert(out, "\"")
            table.insert(out, formatstring(tostring(v)))
            table.insert(out, " (converted to string)\"")
        end
        table.insert(out, ",")
        if not ((tabs == 1 or containsTable or not IsArray) and beautify) then
            table.insert(out, " ")
        end
    end
    table.remove(out, #out)
    if (tabs == 1 or containsTable or not IsArray) and beautify then
        table.insert(out, "\n")
        table.insert(out, string.rep(" ", (tabs-1)*SPACES_PER_TAB))
    end
    table.insert(out, "}")
    return table.concat(out)
end
return function(tabl, ForceDictLayout, Beautify) return export(tabl, ForceDictLayout, Beautify) end
