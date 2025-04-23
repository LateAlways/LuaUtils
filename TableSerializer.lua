--!native

--[[ 
  Usage: 
  local SerializeTable = require(path.to.TableSerializer)

  SerializeTable(Table: {any}, ForceDictionaryLayout: boolean?, Beautify: boolean?)
]]--
SPACES_PER_TAB = 2

function export(tabl, forcedictlayout, beautify, tabs, max_depth)
    if tabs and max_depth and tabs > max_depth then return "Reached max depth" end
    local loop
    local typeof = typeof or type
    if typeof(tabl) ~= "table" then return error("Argument 1 should be of type 'table'.") end
    if _VERSION == "Luau" then loop = function(a) return a end else loop = pairs end
    local function formatstring(str, stringchar)
        local stringchar = stringchar or "\""
        local function isnormalcharacter(char)
            local charbyte = string.byte(char)
            if (charbyte >= 32 and charbyte <= 126) or charbyte == 10 then
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
                    elseif char == "\\" then
                        return "\\\\"
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
    local completeIsArray = false
    local isEmpty = true
    if not forcedictlayout then
        local previous = 0
        for i,_ in loop(tabl) do
            isEmpty = false
            if typeof(i) ~= "number" or i-previous ~= 1 then
                IsArray = false
                completeIsArray = true
            else
                previous = i
            end
            if completeIsArray then
                break
            end
        end
    else
        IsArray = false
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
    local shouldbeautify = (tabs == 1 or not IsArray) and beautify
    local isDict = forcedictlayout or not IsArray
    for i,v in loop(tabl) do
        if shouldbeautify then
            table.insert(out, "\n")
            table.insert(out, tab)
        end
        if isDict then
            table.insert(out, "[")
            if typeof(i) == "string" then
                if formatstring(i) == i and string.find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", string.sub(i, 0,1)) and not forcedictlayout then
                    table.remove(out, #out)
                else
                    table.insert(out, "\"")
                end
                
                table.insert(out, formatstring(i))
                if formatstring(i) ~= i or not string.find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", string.sub(i, 0,1)) or forcedictlayout then
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
            elseif tostring(v) == "1.#QNAN" then
                table.insert(out, "-(0/0)")
            else
                table.insert(out, tostring(v))
            end
        elseif typeof(v) == "table" then
            if tostring(v) == tostring(tabl) then
                table.insert(out, "\"")
                table.insert(out, formatstring(tostring(v)))
                table.insert(out, " (*** cycle table reference detected ***)\"")
            else
                table.insert(out, export(v, forcedictlayout, beautify, tabs + 1, max_depth))
            end
        elseif typeof(v) == "boolean" then
            table.insert(out, tostring(v))
        elseif typeof(v) == "function" and _VERSION == "Luau" then
            table.insert(out, "\"")
            table.insert(out, formatstring(tostring(v)))
            table.insert(out, " (Function name: ")
            table.insert(out, formatstring(debug.info(v, "n")))
            table.insert(out, ")\"")
        else
            table.insert(out, "\"")
            table.insert(out, formatstring(tostring(v)))
            table.insert(out, " (converted to string)\"")
        end
        table.insert(out, ",")
        if not shouldbeautify then
            table.insert(out, " ")
        end
    end
    table.remove(out, #out)
    if not shouldbeautify then
        table.remove(out, #out)
    end
    if shouldbeautify then
        table.insert(out, "\n")
        table.insert(out, string.rep(" ", (tabs-1)*SPACES_PER_TAB))
    end
    table.insert(out, "}")
    return table.concat(out)
end
return function(tabl, ForceDictLayout, Beautify, maxdepth) return export(tabl, ForceDictLayout, Beautify, maxdepth) end
