
% -------------------------------------------------------------------------
% This function is bisection algorithm that compute the largest gam2 such
% that the ring {gam_1<V<gam_2} is valid region of attraction using SOS.   
% -------------------------------------------------------------------------

function gam2 = bisection_top(V,nablaV,f,err,Vref,Vmax,p,dim,approx)

x = mpvar('x',1,dim);
Z2 = monomials(x,0:p); 
options.solver = 'mosek';  
tol = 0.5; 
r = sqrt(2);

gam2 = Vmax; 
gam1 = Vref; 
nb_iter = 1; 

combs = Exp_mon(dim,dim-1); [a,~] = find(combs>1); combs(a,:)=[];
combs = [combs;ones(1,dim)]; combs(combs==0)=-1; combs = combs'; 

while(true)

    if(approx.flag~=0)

        flag = zeros(1,2^dim); 
    
        for i = 1:(2^dim)
            prog = sosprogram(x);
            for j = 1:(dim+3)
                [prog,s{j}] = sossosvar(prog,Z2);
            end
            l = 1e-08*(x*x'); 
            q = (nablaV'*f)+(nablaV.*combs(:,i))'*err+l;
            prog = sosineq(prog,-q-s{end}*(r-sum(x.^2))+s{1}*(V-gam2)-s{2}*(V-gam1));
            [~,info] = sossolve(prog,options);
            flag(i) = info.feasratio;
        end

    else

        prog = sosprogram(x);
        for j = 1:(dim+1)
            [prog,s{j}] = sossosvar(prog,Z2);
        end
        l = 1e-08*(x*x'); 
        q = (nablaV'*f+l);
        prog = sosineq(prog,-q-s{end}*(r-sum(x.^2))+s{1}*(V-gam2)-s{2}*(V-gam1));
        [~,info] = sossolve(prog,options);
        flag = info.feasratio;

    end

    if(all(flag>tol) && abs(gam2-gam1)<0.000001)
        break;
    elseif(all(flag>tol) && nb_iter==1)
        break;
    else
        if(all(flag>tol)) % OK 
           gam1 = gam2;
           gam2 = (gam1+tmp)/2;
        else % KO
            tmp = gam2; 
            gam2 = (gam1+gam2)/2;
        end
    end
    nb_iter = nb_iter+1; 

end

end