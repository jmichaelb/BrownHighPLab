function schema = getStructSchema(src)
% Given a struct, returns a nested list of fields and data types
% for a struct with multiple members

schema = cell2struct(fieldnames(src),{'Field'},2);

for i = 1:length(schema)
    fname = schema(i).Field;
    if isstruct(getfield(src, fname))
        schema(i).Type = getStructSchema(getfield(src, fname));
    else
        schema(i).Type = class(getfield(src, fname));
    end
end
        
    