
% Compute (2^dim)*n equidistant points on the boundary of the hypercube 
% X = [a(1),a(1)+delta] x ... x [a(dim),a(dim)+delta].   

function c = Hypercube_data(dim,n,a,delta)

z = ones(1,n); 
a_temp = [a a+delta]; 
tmp = zeros(dim,n); c = [];

for i = 1:dim
    indx = (1:dim)'~=i; 
    for j = 1:2        
        tmp(indx,:) = Grid(a(indx),delta,nthroot(n,dim-1),dim-1);
        tmp(i,:) = a_temp(i,j)*z; 
        c = [c tmp]; 
    end
end

c = c'; c = unique(c,'rows');

end