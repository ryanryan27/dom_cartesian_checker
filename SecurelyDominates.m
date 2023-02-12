function [dominates, check] = SecurelyDominates(v, graph)
%SECURELYDOMINATES checks is v securely dominates graph


if ~Dominates(v, graph)
    dominates = false;
    return
end

% check vector - if vertex i from graph is guarded, check(i) > 0 else = 0
check = zeros(1,length(v));


for i=1:length(v)
    %check through all nodes not in v to see if they are guarded
    if v(i) == 0
        
        % if a node is adjacent to node i, and not in v, k(i) = 1,
        % if adjacent and in v, k(i) = 2, else k(i) = 0
        k = graph(:,i) + v;
        
        for j=1:length(v)
            %decides which swaps to make to check for guarding
            
            if k(j) == 2
                %sets up the swap set to check if it dominates graph
                swap = v;
                swap(i) = swap(i) + 1;
                swap(j) = swap(j) - 1;
                
                %if the swap set does dominate, node i is guarded
                %hence its check value is incremented
                check(i) = check(i) + Dominates(swap, graph); 
                if(check(i) == 1)
                    break;
                end
            end
        end
        if(check(i) == 0)
            dominates = 0;
            return;
        end
    end
end

dominates = 1;
return;
% 
% %nodes in v are already guarded by themselves
% check = check + v';
% 
% %values in check are > 0 if a node is guarded, 0 if not guarded
% %if some node is not guarded, the set is not securely dominated
% dominates = (min(check) > 0) & Dominates(v, graph);
end

