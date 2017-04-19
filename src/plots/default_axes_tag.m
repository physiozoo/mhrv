function [ tag ] = default_axes_tag( func_name )
%DEFAULT_AXES_TAG Default Tag for axes.
%   func_name: Name of the plotting function.

spf = strsplit(func_name, '_');
tag = strjoin(spf(2:end), '_');
end

