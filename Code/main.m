
clear; % close; % clc
tic
dim = 2; 
x = sym('x',[1 dim]); a = 1; % X = [-a,a]^n. 

% =========================================================================
% 1. Vector field  
% =========================================================================

% 2D system

% F = [x(2) -2*x(1)+(1/3)*x(1)^3-x(2)];
K = 0.2; F = [K*sin(x(1)-x(2))-sin(x(1)) K*sin(x(2)-x(1))-sin(x(2))]; 
% F = [x(2) -(x(1)+x(2))/sqrt(1+(x(1)+x(2))^2)];

% Rescaling of the system

w = 3.5; F = (1/w)*subs(F,x,w*x); 

% 3D system (in development) 
% F = [-x(2) x(2)*x(1)^2+x(1)-x(2)+x(3) x(3)^3-x(3)]; 
            
eig_ex = eig(double(subs(jacobian(F, x),x,zeros(1,dim))));

% =========================================================================
% 2. Computation of the Lyapuov function
% =========================================================================

% Non polynomial vector field: Taylor or Remez. 
% ---------------------------------------------

approx.flag = 1; choice = 'Taylor'; 

% choice can be set as 'Taylor' (for taylor approximation) or 'minimax' for
% a min-max polynomial approximation of the vector field. 

if(approx.flag==1)
    
    approx.type = choice; 
    c = zeros(dim,1); 
    
    if(strcmp(choice,'Taylor'))
        F_eig = F;
        order_tayl = 5; % better to be odd (see paper). 
        F = taylor(F,x,zeros(dim,1),'Order',order_tayl+1);

        % order 5 (for sin/cos system)
        c = [0.7;0.7];

        % order 15 (for sin/cos system)
        % c = [2e-04;2e-04]; 

        % order 5 for sqrt system  
        % c = [1e-18;1.6e+03];  

        for i = 1:dim
            temp = c(i)*sum(x.^2)^((order_tayl+1)/2);
            temp = Convert_sym2mat(temp,dim); 
            approx.err.Expo{i} = temp{1}(:,1:end-1); 
            approx.err.Coeff{i} = temp{1}(:,end); 
        end

    elseif(strcmp(choice,'minimax'))
        F_eig = F; 
        for i=1:dim
            % order of the minimax approximation.
            order_rem = 12;  
            [Coeff,Expo,c(i)] = Pol_approx(F(i),a,choice,order_rem,dim,0);
            % security margin (see paper). 
            c(i) = 1.5*c(i);        
            F(i) = Coeff'*prod(x.^Expo,2);
            approx.err.Expo{i} = zeros(1,dim); 
            approx.err.Coeff{i} = c(i);
        end

    end

else
    approx.err.Expo = []; approx.err.Coeff = []; 
    F_eig = F; 
end

F_sym = F; F = matlabFunction(F_sym,'Vars',{x});
F_eig = matlabFunction(F_eig,'Vars',{x});

% Here, we transform the vector field with variable by stocking the 
% exponant of the vector field. (Numerical purpose) 
% -------------------------------------------------------------------------

F_exp = Convert_sym2mat(F_sym,dim); 

% Choice of the basis functions
% ------------------------------

basis = 'gaussian';
[s,approx] = Basis(dim,basis,approx); 

% A. MONOMIALS 

if strcmp(basis,'monomials')==1

    s.field = F_eig;
    s.field_dec = F_exp;  

% B. GAUSSIAN    
    
else
    
    s.field = F_eig; 

    % change s.field with 'F' to compute a lyapunov function with the
    % approximate polynomial vector field.   

end

truncation = 0;     
[Vec,indx,Val_p,L,Psi_x,Psi_y] = Eigenfunction(s,basis,eig_ex,truncation,dim,approx); 
toc

% If wanted to compute the lyapunov on a grid to have a first insight.
n = 200; 
c = Grid(-ones(dim,1),2,n,dim);
[Lyap,dot_V] = Lyap_evalpoint(basis,Vec,indx,c,s,approx); 

%% Rigorous stability certificate.

choice = 'grid'; 

if(strcmp(choice,'sos'))

    % =====================================================================
    % Validation using SOS
    % =====================================================================
    
    p = 6; % degree of multipliers for SOS relaxation
    tic
    [gam1,gam2,Vmin,V] = Lyap_certificate(basis,s,Vec,indx,F_exp,approx,p);
    toc

else    
    
    % =====================================================================
    % Validation using adaptive grid
    % =====================================================================
    
    tic
    [final_grid,grille_dot,Expo,Coeff,~,~] = AGM(Vec,indx,F_exp,basis,s,approx);
    toc
    tic
    [gam1,gam2] = bisection_grid(final_grid,grille_dot,Expo,Coeff); 
    toc

end
