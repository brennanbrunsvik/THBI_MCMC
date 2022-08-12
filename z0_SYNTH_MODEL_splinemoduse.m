function [model,laymodel,par] = z0_SYNTH_MODEL_splinemoduse(par,ifplot)


if nargin < 2 || isempty(ifplot)
    ifplot=false;
end

global TRUEmodel TLM

% ver = 'orig'; % Index for model parameters to choose from. 
ver = [par.stadeets.sta]'; % Treat the station as determining what model to load. 
if strcmp(ver, 'teststa'); ver = 'orig'; end; % Backward compatibility. 

%% CHOOSE CUSTOM KEY PARAMETERS
% For important parameters I modified, I'll try to do a %<
% Or maybe put the parameters I want to modify from base at the top
if strcmp(ver, 'orig'); % Original(ish) version. 
    selev = 0;
    h_sed = 0;
    h_crust = 45;

    vs_sed = [3.3 3.3];

    kvs_crust = [3.3 3.33 3.74 3.81]';
    cknots = linspace(h_sed, h_sed+h_crust,3)';
    fcknots = (cknots-h_sed)/h_crust;
    k_crust = length(cknots);

    kvs_mantle = [4.1 4.3  4.4 4.0 4.1 4.43]';
    mknots = [h_sed+h_crust, 60, 110, 140, par.mod.maxz]';
    fmknots = (mknots-h_sed-h_crust)/(par.mod.maxz-h_sed-h_crust);
    k_mantle = length(mknots);

    vpvs_crust = 1.8;

    xi_crust = 1.05;
    xi_mantle = 1.0; 
elseif strcmp(ver, 'sed_deep'); % Original(ish) version. 
    selev = 0; 
    h_sed = 4.1; %<
    h_crust = 45;

    vs_sed = [1.5 2.5]; %<

    kvs_crust = [3.3 3.33 3.74 3.81]';
    cknots = linspace(h_sed, h_sed+h_crust,3)';
    fcknots = (cknots-h_sed)/h_crust;
    k_crust = length(cknots);

    kvs_mantle = [4.1 4.3  4.4 4.0 4.1 4.43]';
    mknots = [h_sed+h_crust, 60, 110, 140, par.mod.maxz]';
    fmknots = (mknots-h_sed-h_crust)/(par.mod.maxz-h_sed-h_crust);
    k_mantle = length(mknots);

    vpvs_crust = 1.8;

    xi_crust = 1.05;
    xi_mantle = 1.0; 
end

%% DERIVATIVE PARMS
% DEPTHS
cminz = h_sed;
cmaxz = h_sed+h_crust;
zc = unique([cminz:par.mod.dz:cmaxz,cmaxz])';
mminz = h_sed+h_crust;
mmaxz = par.mod.maxz + selev;
zm = unique([mminz:par.mod.dz:mmaxz,mmaxz])';
% CRUST splines
% dzsp = (cmaxz-cminz)/(k_crust-2);
% knots = [repmat(cminz,1,3),cminz:dzsp:cmaxz,repmat(cmaxz,1,3)]';
% sp = fastBSpline.lsqspline(knots,2,linspace(cminz,cmaxz,k_crust)',kvs_crust); % dummy velocities as placeholder
% cspbasis = sp.getBasis(zc); cspbasis = cspbasis(:,2:end-1);
[ cspbasis ] = make_splines( cknots,par, zc);
% MANTLE splines
% dzsp = (mmaxz-mminz)/(k_mantle-2);
% knots = [repmat(mminz,1,3),mminz:dzsp:mmaxz,repmat(mmaxz,1,3)]';
% sp = fastBSpline.lsqspline(knots,2,linspace(mminz,mmaxz,k_mantle)',kvs_mantle); % dummy velocities as placeholder
% mspbasis = sp.getBasis(zm); mspbasis = mspbasis(:,2:end-1);
[ mspbasis ] = make_splines( mknots,par, zm);
% OVERALL
M = 1 + 2 + 1 + k_crust + k_mantle + 1;

%% MAKE ALL PARAMETER STRUCTURES
sed = struct('h',h_sed,'VS',vs_sed);
crust = struct('h',h_crust,'Nsp',k_crust+1,'Nkn',k_crust,'VS_sp',kvs_crust,'vpvs',vpvs_crust,'xi',xi_crust,'splines',cspbasis,'knots',cknots,'fknots',fcknots,'z_sp',zc);
mantle = struct('Nkn',k_mantle,'Nsp',k_mantle+1,'VS_sp',kvs_mantle,'xi',xi_mantle,'splines',mspbasis,'knots',mknots,'fknots',fmknots,'z_sp',zm);
% data = struct('sigmaPsRF',par.mod.data.prior_sigmaPsRF,...
%               'sigmaSpRF',par.mod.data.prior_sigmaSpRF,...
%               'sigmaSW',par.mod.data.prior_sigmaSW);
data = ([]);

%% MODEL WITH ALL PARMS
model = struct('sedmparm',sed,'crustmparm',crust,'mantmparm',mantle,...
               'datahparm',data,'M',M,'selev',selev);
           
%% TURN PARMS INTO REAL TARGET MODEL
TRUEmodel = make_mod_from_parms(model,par);
% plot_quickmodel(par,model,model); warning('Remove this line'); 
% same format...

TRUEmodel.Z = TRUEmodel.z;
TRUEmodel.vs = TRUEmodel.VS;
TRUEmodel.vp = TRUEmodel.VP;


% % RHO is effed up = we don't agree on rho scaling, but it matters a lot for
% % the elastic moduli that propmat actually uses. 
% rho = linterp(trymod.z,trymod.rho,Z);
% % vs = linterp(trymod.z,trymod.VS,Z)+0.3;
% vp = linterp(trymod.z,trymod.VP,Z);



%% ===================  LAYERISE PROFILE  ===================
[zlayt,zlayb,Vslay] = ...
    layerise(TRUEmodel.z,TRUEmodel.vs,par.forc.mindV/3,0); 
nlay = length(Vslay);

% S to P and rho structure
xs = 1:find(zlayb==TRUEmodel.zsed); if TRUEmodel.zsed ==0, xs = []; end
xc = find(zlayt==TRUEmodel.zsed):find(zlayb==TRUEmodel.zmoh);
xm = find(zlayt==TRUEmodel.zmoh):nlay;
Vplay = [sed_vs2vp(Vslay(xs));...
         TRUEmodel.vpvs*Vslay(xc);...
         mantle_vs2vp(Vslay(xm),mean([zlayt(xm),zlayb(xm)],2))];
rholay = [sed_vs2rho(Vslay([xs,xc]));...
          mantle_vs2rho(Vslay(xm),mean([zlayt(xm),zlayb(xm)],2))];
xilay = [ones(length(xs),1);...
         TRUEmodel.cxi*ones(length(xc),1);...
         TRUEmodel.mxi*ones(length(xm),1)]; % S radial anisotropy
philay = ones(nlay,1); % P radial anisotropy
% warning('Changing philay')
% philay2 = 1./xilay; 
% philay = (philay + philay2) ./2; 
% disp(philay);
% philay = philay2; 
warning('NO p wave anisotropy!!!')
etalay = ones(nlay,1); % eta anisotropy

TLM = struct('zlayt',zlayt,'zlayb',zlayb,'Vs',Vslay,'Vp',Vplay,'rho',rholay,'nlay',nlay,'xi',xilay,'phi',philay,'eta',etalay);
if any(isnan(TLM.rho))
    error('NaN densities')
end

%% ====== Calculate average VS in crust. For h-kappa stacks === brb2022.02.08

z2 = TRUEmodel.z; % Need to operate on z a little bit. 
indLay = z2(2:end) == z2(1:end-1); % Layers indecies. 
indLay = find(indLay)+1; % Bottom of layers. 
z2(indLay) = z2(indLay) + 0.01; % Need unique points. 
timeToDep = cumtrapz(z2, 1./TRUEmodel.vs); % Time it would take a vertically travelling ray to go from surface to some depth. 

TRUEmodel.vsAvCrust = h_crust / interp1(z2, timeToDep, h_crust); % "Average" travel time in crust. 
% brb2022.02.09: This assumes a station with zero elevation. It should be fine for most synthetic tests. TODO we do have an optional elevation value in the synthetic model. I should verify that z includes z<0 - if so, no code change is needed. 

%% PLOT FINAL MODEL
if ifplot
figure(95); clf; set(gcf,'pos',[120 151 920 947])
subplot(131), hold on;
plot(TRUEmodel.vp,TRUEmodel.z,'-b','Linewidth',1.5);
set(gca,'ydir','reverse','fontsize',14);
subplot(132), hold on;
plot(TRUEmodel.vs,TRUEmodel.z,'-b','Linewidth',1.5);
set(gca,'ydir','reverse','fontsize',14);
subplot(133), hold on;
plot(TRUEmodel.rho,TRUEmodel.z,'-b','Linewidth',1.5);
set(gca,'ydir','reverse','fontsize',14);
end

model = TRUEmodel;
laymodel = TLM;


end

