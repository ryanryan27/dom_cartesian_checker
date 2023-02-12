function ss = dom_cartesian_check(graph, pattern, varargin)


if(numel(varargin) > 0)
    dom_type = varargin{1};
    
    if(isequal(dom_type, 'sd'))
        dom_type = @SecurelyDominates;
    elseif(isequal(dom_type,'td'))
        dom_type = @td;
    elseif(isequal(dom_type,'dom'))
        dom_type = @Dominates;
    end
else
    dom_type = @Dominates;
end

% labelling

%1 - 2 - 3 - 4 - 5 - 6 -...
%|   |   |   |   |   |  ...
%w+1-w+2-w+3-w+4-w+5-w+6...
ss=0;

p = size(pattern,2);


padding = 3;

width = p + padding*2;

m = length(graph);

G = cartesian_product(graph, make_path(width));


n = size(G,1);

% place the guards for the outer copies
guards = zeros(1,size(G,1));

for i=0:m-1
    for j=1:padding
        guards(i*width + j) = 1;
        guards((i+1)*width + 1 - j) = 1;
    end
end

% collect all of the permutations in a cell
patterns = {};

for i=1:p

    %get the labels for each vertex in the copies of interest
    verts = zeros(1,m);
    for j=0:m-1
        verts(j+1) = j*width + i+padding;
    end

    % get permutations choosing appropriate amount of guards
    patterns{i} = nchoosek(verts, pattern(i));

end


% get total number of permutations of the pattern
pcount = 1;
for i=1:p
   pcount = pcount*size(patterns{i},1);
end

% get all permutations that dominate
for i=1:pcount
    divnum = 1;
    layout = zeros(1,n);

    % build each of the layouts copy by copy
    for j=1:p

        s = size(patterns{j},1);

        % possible arrangements for this copy
        gds = patterns{j};

        % make sure all arrangements of patterns are accounted for
        % e.g. first copy gives patterns 1,2,3,1,2,3,1,2,3,1,2,3,...
        %     second copy gives patterns 1,1,1,2,2,2,3,3,3,1,1,1,...
        %      third copy gives patterns 1,1,1,1,1,1,1,1,1,2,2,2,...
        index = mod(ceil(i/divnum),s);

        % cant have 0 index patterns, so we make it the last one
        if (index == 0)
            index = s;
        end

        % prep for next copy
        divnum = divnum*s;

        % assign the pattern to the layout
        layout(gds(index,:)) = 1;


    end
   

    % for each generated layout, only keep it if it is dominating
    

    
    if(dom_type((layout + guards)', G))
        ss = 1;
        return
    end
end


end
