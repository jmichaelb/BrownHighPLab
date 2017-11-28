function d = extractFlat(src,spec)
% Extracts data from a nested source and returns a struct with data
% flattened - upper levels of the nesting will be repeated for every record
% in the leaf level.  Currently, the lowest level field will dictate the
% number of rows returned, with each value of the lowest level field
% getting a separate row in the output.  Any fields not in the direct 
% hierarchy of the lowest level field will be represented with an array.  
% If multiple fields are requested at a low level, the first one requested
% will dictate the number of rows.  If the lowest level field is part of a
% struct array, other fields at the same level in the nested struct will be
% represented on each row.  Note that fields can be requested in any order.
%
%   src is the source, and can either be an existing Matlab variable or a 
%   filename.  If src is a string, it will be assumed to be a filename.  
%   Otherwise, pass in the actual variable from which data will be
%   extracted.

%   spec is the specification of what you want to get out of the source.
%   This should be an CELL array of strings listing field names to extract 
%   from the source.  Nested fields can be simply indicated with dot syntax
%   (e.g. l1field.l2field.l3field).  Do not include a specification for the
%   top level data structure (src).  A field that is just a container for
%   another struct should not be listed separately if individual fields
%   from the struct are also listed.

if isstring(src)
    srcd = load(src);
else
    srcd = src;
end

srcSch = getStructSchema(src);

% check that all fields in the spec exist



% find lowest level nested field that determines number of rows to return
d = struct;
dots = cellfun(@(c) strfind(c,'.'),spec,'UniformOutput',false);
dotLevs = cellfun(@(c) length(c), dots);
drivers = spec(dotLevs == max(dotLevs));
driverParent = cell2mat(regexp(drivers{1},'.*(?=\.)','match'));


% getNestedFieldIdx = @(sch) find(arrayfun(@(f) isstruct(f.Type), sch) > 0);
% getNestedFieldName = @(stk) = 
% nestedFields = [];
% schStack = [srcSch];
% fldStack = [];
% nestedFieldIdx = getNestedFieldIdx(srcSch);
% while ~isempty(nestedFieldIdx)
%     lev = length(schStack);
%     workingSch = schStack(end);
%     for i = nestedFieldIdx
%         if ~isstruct(workingSch(i).Type)
%             nfn = cell2mat(cellfun(@(f) [f '.'], fldStack,'UniformOutput',false));
%             nestedFields(length(nestedFields)+1) = struct('Name',nfn(1:end-1),'Level',lev);
%         else if 
%     end
%     
% end









