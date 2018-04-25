function pot = evalDL(xEvl,f,bdy,opt)
    Np = size(xEvl,1);
    pot = zeros(Np,1);
    Nobs = numel(bdy);
    for o=1:Nobs
        if exist('opt','var') && ~isempty(opt) 
            pot = pot + evalDL_aux(xEvl,f(o),bdy(o),opt);
        else
            pot = pot + evalDL_aux(xEvl,f(o),bdy(o));
        end
    end

end

function pot = evalDL_aux(xEvl,f,bdy,opt)

Np = size(xEvl,1);

pot = zeros(Np,1);
    
ind=[];   

minR = 1e10*ones(Np,1);
pat = zeros(Np,1);
loc = zeros(Np,1);   

for j = 1:bdy.nPat

    nj = bdy.nPts(j);

    R1 = repmat(xEvl(:,1),1,nj^2)-repmat(bdy.Xp(:,1,j)',Np,1);
    R2 = repmat(xEvl(:,2),1,nj^2)-repmat(bdy.Xp(:,2,j)',Np,1);
    R3 = repmat(xEvl(:,3),1,nj^2)-repmat(bdy.Xp(:,3,j)',Np,1);   

    Ny1 = repmat(bdy.Nrm(:,1,j)',Np,1);
    Ny2 = repmat(bdy.Nrm(:,2,j)',Np,1);
    Ny3 = repmat(bdy.Nrm(:,3,j)',Np,1);

    R = sqrt(R1.^2+R2.^2+R3.^2);

    dGdn = (R1.*Ny1+R2.*Ny2+R3.*Ny3)./(4*pi*R.^3);

    Jcb = bdy.Jp(:,j).*bdy.Wp;

    F = f.density_to_vector(j);

    pot = pot + dGdn*(F.*Jcb);

    [minR_aux,loc_aux] = min(R,[],2);
    a = find(minR_aux<minR);
    minR(a) = minR_aux(a);
    loc(a) = loc_aux(a);
    pat(a) = j;

end

a   = find(minR<bdy.tol);

ind = [ind;[a,loc(a),pat(a)]];

if ~isempty(ind)

    dfu = f.diff(bdy,'U');
    dfv = f.diff(bdy,'V');

    dfuu = dfu.diff(bdy,'U');
    dfuv = dfv.diff(bdy,'U');
    dfvv = dfv.diff(bdy,'V');         
    
    Nnear = size(ind,1);

    for i = 1:Nnear

        indX = ind(i,1);
        
        x = xEvl(indX,:);
        
        pot(indX)=0.0;                        

        indX0 = ind(i,2);
        idX0 = ind(i,3);
                
        x0 = bdy.Xp(indX0,:,idX0);
        
        n0 = bdy.nPts(idX0);

        if mod(indX0,n0)==0
            q = bdy.nPts(idX0);
        else
            q = mod(indX0,n0);
        end

        p = 1+(indX0-q)/n0;
        
        C = bdy.invA(p,q,idX0);

        locX0 =bdy.loc_to_glob(p,q,idX0);  
        
        f0 = f.vec(locX0,:);
        fU = dfu.vec(locX0,:);
        fV = dfv.vec(locX0,:);
        fUU = dfuu.vec(locX0,:);
        fUV = dfuv.vec(locX0,:);
        fVV = dfvv.vec(locX0,:);

        rhs1 = [f0;fU;fV]; 
        rhs2 = 0*[f0;fU;fV];
        rhs3 = [fUU;fVV;fUV]; 

        c= C*[rhs1;rhs2;rhs3];

        for j=1:bdy.nPat

            R1 = x(1)-bdy.Xp(:,1,j);
            R2 = x(2)-bdy.Xp(:,2,j);
            R3 = x(3)-bdy.Xp(:,3,j);

            R = sqrt(R1.^2+R2.^2+R3.^2)';

            G = 1./(4*pi*R);
            dGdn = dot(bdy.Nrm(:,:,j),[R1,R2,R3],2)'.*G./(R.^2);
           
            Jcb = bdy.Jp(:,j).*bdy.Wp;

            F = f.density_to_vector(j,1);

            R01 = x0(1)-bdy.Xp(:,1,j);
            R02 = x0(2)-bdy.Xp(:,2,j);
            R03 = x0(3)-bdy.Xp(:,3,j);
            
            HPol = [ones(size(R01)), -R01, -R02, -R03, R01.*R02, R01.*R03, R02.*R03,...
                    R01.^2 + R02.^2 - 2*R03.^2, R01.^2 - R02.^2];
            
            P  = HPol*c(:);
            Q  = dot(bdy.Nrm(:,:,j), [c(2)-c(5)*R02-c(6)*R03-2*c(8)*R01-2*c(9)*R01,...
                              c(3)-c(5)*R01-c(7)*R03-2*c(8)*R02+2*c(9)*R02,...
                              c(4)-c(6)*R01-c(7)*R02+4*c(8)*R03],2); 

            pot(indX) = pot(indX) + G*(Q.*Jcb)+dGdn*((F-P).*Jcb);
            
        end

        % ... if the point lies is inside the surface
        
        if exist('opt','var') && ~isempty(opt) 
            
            if strcmp(opt,'int')
                
                r1 = x0(1)-x(1);
                r2 = x0(2)-x(2);
                r3 = x0(3)-x(3);
            
                HPol = [1, -r1, -r2, -r3, r1.*r2, r1.*r3, r2.*r3,...
                        r1.^2 + r2.^2 - 2*r3.^2, r1.^2 - r2.^2];
            
                pot(indX) =  pot(indX) - HPol*c;
                
            end
            
        end
        
    end

end

end


