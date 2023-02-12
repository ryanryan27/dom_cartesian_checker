function A = cartesian_product(P1,P2, varargin)



N1 = size(P1,1);
N2 = size(P2,1);
if(~isempty(varargin))
    A = zeros(N1*N2,N1*N2);
else
A = sparse(N1*N2,N1*N2);
end
%

for i=1:N1
    A((i-1)*N2+1:i*N2,(i-1)*N2+1:i*N2) = P2;
end

for i=1:N1
    for j=i+1:N1
        if(P1(i,j))
            for k=1:N2
                A((i-1)*N2+k,(j-1)*N2+k) = 1;
                A((j-1)*N2+k,(i-1)*N2+k) = 1;
            end
        end
    end
end