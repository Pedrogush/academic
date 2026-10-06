function estr = test_mtruct(varargin)
estr = struct();
for i=1:nargin
estr.(inputname(i)) = varargin(i);
end
end