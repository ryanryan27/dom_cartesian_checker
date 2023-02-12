function [too_long, dense_ptrns, inf_ptrns] = check_cartesian_patterns(graph, dense_patterns, infeasible_patterns, weight, block_size, max_size, varargin)
tic;
verbose = 0;

single_stack = 0;

too_long = {};

checked = {};

dom_type = 'sd';

if ~isempty(varargin)
    dom_type = varargin{1};
end

%generate base patterns
base_patterns = {};

count = 1;
for i=1:weight-1
    bps = patterns_from_weight(i, block_size);
    
    for j = 1:size(bps,1)
        p = bps(j,:);
        if(~already_in_ptrn(p, base_patterns))
            base_patterns{count} = p;
            count = count + 1;
        end
        
    end
end


dense_ptrns = [{weight+1} dense_patterns];
inf_ptrns = infeasible_patterns;

increment_toggle = 1;
extend_toggle = -1;

stack = {};

%add base patterns to the stack
for i = 1:numel(base_patterns)
    push_stack(base_patterns{i}, 1, 0);
    
end

while (has_elements(stack))
    
    if(verbose==1)
        clc;
    end
    
    [p, ind, prev_operation] = pop_stack();
    
    if(verbose == 0)
        %disp('TAKE FROM STACK');
        iteration_display(p,ind);
    end
    
    
    
    %check if its been checked before
    %dont store if base pattern is on an end
    if(ind ~= 1 && ind ~= length(p)-block_size+1)
        
        if(already_in_ptrn(p, checked))
            disp('already checked');
            continue
        end
        checked{numel(checked)+1} = p;
    end
    
    
    %if compensate or too dense, continue loop
    if(in_ptrn_list(p, dense_ptrns) || compensates(p, ind))

        disp('compensated or dense');
        
        add_to_dense(p, prev_operation);
       
        increment_sides(p,ind);
        
    %else if not feasible, increment ends (independently, two elements) and add to stack
    elseif(in_ptrn_list(p, inf_ptrns)||~feasible(p))
        disp('infeasible');
        
        if(~in_ptrn_list(p,inf_ptrns))
            inf_ptrns{numel(inf_ptrns)+1} = p;
        end
        
        increment_sides(p, ind);
    %else, extend pattern either end and add to stack
    else
        increment_sides(p, ind);
        extend_sides(p,ind);
        
        if(ind + block_size -2< length(p)-max_size && ind > max_size)
            too_long{numel(too_long)+1} = [-1*ind p];
            disp('this one got too long');
        end
        
    end
    if(verbose == 1)
        disp('Current Stack:');
        cell_display(stack);
        fprintf(1,'\n');
        disp('Current pattern');
        fprintf(1,'%i ',p);
        fprintf(1,'\n\n');
        disp('Current weight pattern');
        fprintf(1,'% i',weight_pattern(p));
        fprintf(1,'\n\n');
        pause
    end
    
end
fprintf(1,'\n\n');

if(isempty(too_long))
    disp('--------------------');
    disp('      Solved!');
    disp('--------------------');
else
    disp('xxxxxxxxxxxxxxxxxxxx');
    disp('    Not solved!');
    disp('xxxxxxxxxxxxxxxxxxxx');
end
fprintf(1, '\nTime Taken: %.2fs\n', toc);

%--------------------------------------------------------------------------
%                       FUNCTION DEFINITIONS
%--------------------------------------------------------------------------
    function push_stack(p, ind, op)
        if single_stack
            stack{numel(stack) + 1} = [ind, op, p];
            
        else
            stack_ind = length(p) - block_size + 1;

            if (numel(stack) < stack_ind)
                stack{stack_ind} = [ind, op, p];
            else
                stack{stack_ind} = [stack{stack_ind} ; ind, op, p];
            end
        end
        
    end

    function [p, ind, op] = pop_stack()
        
        if single_stack
            
            data = stack{numel(stack)};
            ind = data(1);
            %-2 ext left, -1 inc left, 0 none, 1 inc right, 2 ext right
            op = data(2);
            p = data(3:length(data));
            stack = stack(1:numel(stack)-1);
            return
            
        else
            for ii = 1:numel(stack)
                substack = stack{ii};
                if (isempty(substack))
                    continue
                end
                rind = size(substack,1);
                ind = substack(rind, 1);
                op = substack(rind, 2);
                p = substack(rind, 3:size(substack,2));

                stack{ii} = substack(1:rind-1,:);
                return
            end
        end
        p = -1;
        ind = -1;
        op = -1;
        
    end

    function has = has_elements(stck)
        has = 0;
        for ii = 1:numel(stck)
            if (isempty(stck{ii}))
                continue
            end
            has = 1;
            return
        end
        
    end

    function extend_sides(p, ind)
        
        if(extend_toggle > 0)
            
            if(ind + block_size -2>= length(p)-max_size)
                p2 = [p 0];
                push_stack(p2, ind, 2);
                disp('nothing wrong here - extend right');
            end
            if(ind <= max_size)
                p3 = [0 p];
                push_stack(p3, ind+1, -2);
                disp('nothing wrong here - extend left');
            end
            
        else
            if(ind <= max_size)
                p3 = [0 p];
                push_stack(p3, ind+1, -2);
                disp('nothing wrong here - extend left');
            end
            if(ind + block_size -2>= length(p)-max_size)
                p2 = [p 0];
                push_stack(p2, ind, 2);
                disp('nothing wrong here - extend right');
            end
            
        end
        extend_toggle = extend_toggle*-1;
        
        
    end

    function increment_sides(p, ind)
        
        if(increment_toggle > 0)
            
            if(ind ~= 1 && p(1) < length(graph))
                p2 = p;
                p2(1) = p2(1) + 1;
                push_stack(p2, ind, -1);
            end
            if(ind ~= length(p) - block_size +1 && p(length(p)) < length(graph))
                p3 = p;
                p3(length(p3)) = p3(length(p3)) + 1;
                push_stack(p3, ind, 1);
            end
        else
            if(ind ~= length(p) - block_size +1 && p(length(p)) < length(graph))
                p3 = p;
                p3(length(p3)) = p3(length(p3)) + 1;
                push_stack(p3, ind, 1);
            end
            if(ind ~= 1 && p(1) < length(graph))
                p2 = p;
                p2(1) = p2(1) + 1;
                push_stack(p2, ind, -1);
            end
        end
        increment_toggle = increment_toggle*-1;
        
    end


    function add_to_dense(p, prev_operation)
        
        if(~already_in_ptrn(p,dense_ptrns))
            
            
            if(prev_operation == -1)
                pt = p;
                pt(1) = pt(1)-1;
                if(in_ptrn_list(pt, inf_ptrns) && ~in_ptrn_list(p(2:length(p)),dense_ptrns))
                    dense_ptrns{numel(dense_ptrns)+1} = p(2:length(p));
                end
                
            elseif(prev_operation == 1)
                pt = p;
                pt(length(pt)) = pt(length(pt))-1;
                if(in_ptrn_list(pt, inf_ptrns) && ~in_ptrn_list(p(1:length(p)-1),dense_ptrns))
                    dense_ptrns{numel(dense_ptrns)+1} = p(1:length(p)-1);
                end
                
            elseif(prev_operation == -2)
                pt = p(2:length(p));
                if(~in_ptrn_list(pt,dense_ptrns))
                    dense_ptrns{numel(dense_ptrns)+1} = pt;
                end
            elseif(prev_operation == 2)
                pt = p(1:length(p)-1);
                if(~in_ptrn_list(pt,dense_ptrns))
                    dense_ptrns{numel(dense_ptrns)+1} = pt;
                end
            end
            
        end
        
    end

    function [cmp] = compensates(ptrn, ind)
        wgt = weight_pattern(ptrn);
        cmp = 0;
        if(wgt(ind) >= weight)
            cmp = 1;
            return
        end
        
        %need to do something smart here :/
        
        %this just looks for weight-k being adjacent to a weight+k
        
        if(ind > 2)
            if((wgt(ind-1)+wgt(ind) >= 2*weight) && (wgt(ind-2) + wgt(ind-1) + wgt(ind) >= 3*weight))
                cmp = 1;
                return
            end
        end
        
        if(ind < length(wgt)-1)
            if((wgt(ind) + wgt(ind+1) >= 2*weight) && (wgt(ind) + wgt(ind+1) + wgt(ind+2) >= 3*weight))
                cmp = 1;
                return
            end
        end
        
        % weight-1 is uniquely adjacent to a weight+1, or adjacent to any
        % weight+2 or greater
        
    end

    function [fs] = feasible(ptrn)
            fs = dom_cartesian_check(graph, ptrn, dom_type);
    end

    function [wgt] = weight_pattern(ptrn)
        if(length(ptrn) < block_size)
            wgt = sum(ptrn);
            return
        end
        wgt = [];
        for ii=1:length(ptrn)-block_size+1
            wgt = [wgt sum(ptrn(ii:ii+block_size-1))];
        end
        
    end


    function cell_display(cell)
        for ii=1:length(cell)
            m = cell{ii};
            if single_stack
                sz = size(m,2);
                fprintf(1,'(%i,%i) ',m(1:2));
                fprintf(1,'%i ',m(3:sz));
            else
                sz = size(m,2);
                disp('----------');
                fprintf(1,'Pattern Length: %i\n', sz-2);
                disp('----------');
                for jj = 1:size(m,1)
                    fprintf(1,'(%i,%i) ',m(jj,1:2));
                    fprintf(1,'%i ',m(jj,3:sz));
                    fprintf(1,'\n');
                end
            end
            fprintf(1,'\n');
        end
    end

    function iteration_display(p, ind)
        fprintf(1,'\n================New Pattern================\n');
        fprintf(1,'\n');
        fprintf(1,'----Stack----\n');
        if(single_stack)
            fprintf(1, 'Patterns remaining: %i\n', numel(stack));
        else
            for ii = 1:numel(stack)
                fprintf(1, '%i-Patterns: %i remaining\n', [size(stack{ii},2)-2 size(stack{ii},1)]);  
            end
        end
        fprintf(1, '-------------\n');
        fprintf(1,'\n');
        %stack
        fprintf(1, '---Pattern---\n');
        fprintf(1, '%2i ', p);
        fprintf(1,'\n');
        for ii = 1:3*ind-2
            fprintf(1,' ');
        end
        for ii = 1:block_size
            fprintf(1,'x  ');
        end
        fprintf(1, '\n-------------\n');
        fprintf(1,'\n');
        
        fprintf(1, '---Weights---\n');
        fprintf(1, '%2i ', weight_pattern(p));
        fprintf(1,'\n');
        for ii = 1:3*ind-2
            fprintf(1,' ');
        end
        fprintf(1,'x\n');
        fprintf(1, '-------------\n');
        fprintf(1,'\n');
        
        fprintf(1, 'Result: ')
        
    end

    function conts = in_ptrn_list(ptrn, ptrn_list)
        rev = flip(ptrn);
        conts = 0;
        for ii=1:numel(ptrn_list)
            a = is_subptrn(ptrn,ptrn_list{ii});
            if(a || is_subptrn(rev, ptrn_list{ii}))
                conts = 1;
                return
            end
            
        end
        
    end

    function conts = already_in_ptrn(ptrn, ptrn_list)
        rev = flip(ptrn);
        conts = 0;
        for ii=1:numel(ptrn_list)
            if(isequal(ptrn,ptrn_list{ii}) || isequal(rev, ptrn_list{ii}))
                conts = 1;
                return
            end
            
        end
        
    end

    function conts = is_subptrn(ptrn, smaller)
        conts = 0;
        
        for ii=1:length(ptrn)-length(smaller)+1
            if(isequal(ptrn(ii),smaller(1)))
                for jj=1:length(smaller)
                    if(isequal(ptrn(ii+jj-1),smaller(jj)))
                        if(jj==length(smaller))
                            conts = 1;
                            return
                        end
                        continue
                    else
                        break
                    end
                end
            end
        end
        
    end


end
