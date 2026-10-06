function estr = convert_names_to_fields(varargin)
estr = struct();
for i=1:nargin
estr.(inputname(i)) = cell2mat(varargin(i));
end
end