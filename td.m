function doms = td(v, graph)


if(size(v,1) == 1)
    V = v*graph;
else
    V = v'*graph;
end

doms = (min(V) > 0);
    

end