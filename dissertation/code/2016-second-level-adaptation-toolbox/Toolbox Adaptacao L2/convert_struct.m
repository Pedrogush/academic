function varargout = convert_struct(struct)
l = struct2cell(struct);
for k=1:length(l)
varargout(k) = l(k);
end
end
