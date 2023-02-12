function A = make_path(n)
    A=zeros(n,n);
    
    for i = 1:n-1
        A(i,i+1) = 1;
        A(i+1,i) = 1;
    end
    
end

