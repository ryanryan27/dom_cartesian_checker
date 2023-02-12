function [dominates] = Dominates(v,graph)
%DOMINATES checks if g dominates graph
%   v is a vector of size n of 0s and 1s, where v(n) is 1 if vertex
%   n from graph is part of the dominating set, and 0 otherwise.
%   graph is an adjacency matrix of a graph of size nxn

if(size(v,1) == 1)
    V = v*graph + v;
else
    V = v'*graph + v';
end

dominates = (min(V) > 0);
    
end

