# TableSerializer
## About
Transforms a table containing lua objects (number, string, boolean, table, etc...) into a string.

## Usage
> Returns a string version of the `table` passed in valid lua/luau syntax.
```luau
function SerializeTable(Table: {any}, ForceDictionaryLayout: boolean?, Beautify: boolean?): string
```
