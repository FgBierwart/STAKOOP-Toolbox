
% =========================================================================
% INPUT: 
% -----
% 
% - final_grid : Matrix where each rows is coordinates in X where the time
%                derivative of V (computed with AGM.m) is striclty negative. 
%                For each row, firsts column are the coordinates and the 
%                last one is the stepsize of the cell. E.g, [-0.5 -0.5 1]. 
%                Cell defined by the coordinates (-0.5,0.5), (-0.5,0.5), 
%                (0.5,-0.5), (0.5,0.5). 
% 
% - grille_dot : Matrix with construction as final_grid contains the 
%                remaining cells in X which are not in final_grid.  
%
% - Expo : Matrix containing the exponents of monomials in V (computed 
%          with AGM.m). 
% 
% - Coeff : Vector conntaining the coefficients of V (computed 
%           with AGM.m) associated to monomials defined in Expo.  
%
% OUTPUT: 
% ------
% 
% This function return the basin of attraction approximation delimited by
% the set {gam_1 <= V <= gam_2} 
%
% =========================================================================

function [gam1,gam2] = bisection_grid(final_grid,grille_dot,Expo,Coeff)

G = [grille_dot zeros(length(grille_dot),1);...
final_grid ones(length(final_grid),1)];

dim = 2;
v = cell(length(G),1);

% Computation of the lyapunov candidate onto the grid cells
V_grid = zeros(size(G,1),2^dim); 
[Coeff,Expo,C_nrm_grad,E_nrm_grad] = grad_norm(Expo,Coeff); 

combs = Exp_mon(dim,dim-1);
combs = [combs;ones(1,dim)];
for i = 1:length(G)
    v{i} = G(i,1:end-2)+combs*G(i,end-1);
    V_grid(i,:) = eval_pol(Coeff,Expo,v{i});
end

C{1} = Expo; C{2} = Coeff; C{3} = E_nrm_grad; C{4} = C_nrm_grad; C{5} = v;

% Computation of a bound over the norm of the gradient of V

K = Bound_Grad_Pol(E_nrm_grad,C_nrm_grad,G(:,1:end-1),'max',combs); 

x = sym('x',[1 dim]); P = (Coeff(1))*prod(x.^Expo(1,:),2);

for i = 2:length(Coeff)
    P = P + Coeff(i)*prod(x.^Expo(i,:),2);
end

P = matlabFunction(P,'Vars',{x});
 
N = 100; t = Hypercube_data(dim,N,-ones(dim,1),2);
eval_V = P(t); 

% Here, we select two max and min value of V so that the ROA lies in 
% [-1,1]^dim. 

Vmax = min(eval_V); Vmin = min(V_grid,[],'all');
nb_points = 200; 
l = sort(linspace(Vmin,Vmax,nb_points),'descend');
k = 1; 

% =========================================================================
% Computation of reference level set 
% =========================================================================

while(true)
    
   % Since we compute a reference level set, we need to be sure that it is
   % valid from above and below. See IsValid.m for more detailed about the
   % detection of valid level curve. 

   [~,flag1] = IsValid(G,V_grid,l(k),C,'top',K,P); 
   [~,flag2] = IsValid(G,V_grid,l(k),C,'bot',K,P); 

    if(flag1==1 && flag2==1)
        break;
    end

    k = k+1;
    
end

Vref = l(k); 

% =========================================================================
% Bisection for the top level set 
% =========================================================================

gam2 = Vmax; 
gam1 = Vref; 
nb_iter = 1; 

while(true)

    % We check if the level curve is valid (from above)
    [~,flag] = IsValid(G,V_grid,gam2,C,'top',K,P);

    % If it is the case, we check if all cells lying insice the reference
    % level set and the computed level set are valid. This will define a
    % ROA. 
    tmp2 = find(min(V_grid,[],2)>=gam1 & max(V_grid,[],2)<=gam2);
    tmp2 = length(tmp2)==sum(G(tmp2,end)); 

    if(flag==1 && tmp2 && abs(gam2-gam1)<0.000001)
        break;
    elseif(flag==1 && tmp2 && nb_iter==1)
        break;
    else
        if(flag==1 && tmp2) % OK 
           gam1 = gam2;
           gam2 = (gam1+tmp)/2;
        else % KO
            tmp = gam2; 
            gam2 = (gam1+gam2)/2;
        end
    end

    nb_iter = nb_iter+1;
    
end

% =========================================================================
% Bisection for the bottom level set 
% =========================================================================

gam2_tmp = Vref; 
gam1 = Vmin; 
nb_iter = 1; 

while(true)

    % We check if the level curve is valid (from below)
    [~,flag] = IsValid(G,V_grid,gam1,C,'bot',K,P);

    % If it is the case, we check if all cells lying insice the reference
    % level set and the computed level set are valid. This will define a
    % ROA.
    tmp2 = find(min(V_grid,[],2)>=gam1 & max(V_grid,[],2)<=gam2_tmp);
    tmp2 = length(tmp2)==sum(G(tmp2,end)); 

    if(flag==1 && tmp2 && abs(gam2_tmp-gam1)<0.000001)
        break;
    elseif(flag==1 && tmp2 && nb_iter==1)
        break;
    else
        if(flag==1 && tmp2) % OK 
           gam2_tmp = gam1;
           gam1 = (gam2_tmp+tmp)/2;
        else % KO
            tmp = gam1; 
            gam1 = (gam1+gam2_tmp)/2;
        end
    end

    nb_iter = nb_iter+1;

end

end