clear all
fs = 97656;
pathname = uigetdir(matlabroot,'MATLAB Root Folder');
files = dir( fullfile(pathname,'*.mat') );   % list all *.mat files
files = {files.name}';                       % file names
fname = fullfile(pathname,files);     % full path to file

ind(length(fname),2) = 0;
data = importdata(fname{1});
x = data.vibration;

[ deterministic, random,r_cepstrum ] = cpw(x);
%%


[Kurt,F] = pkurtosis(random,fs,128);
%Kurt = Kurt.^2;
ind(1,:) = [max(Kurt) rms(Kurt)];

S = [];
S = [S Kurt];
figure;
ax = gca;
ax.XLim = [0 50];
for i=2:length(fname)
    data = importdata(fname{i});
    data = data.vibration;
    [ deterministic, random,r_cepstrum ] = cpw(data);
    [Kurt,F] = pkurtosis(random,fs,128);
    %Kurt = Kurt.^2;
    S = [S Kurt];
    %
    disp(i)
    ind(i,:) = [max(Kurt) rms(Kurt)];
    
    if i>3
        ind(1:i,:) = sgolayfilt(ind(1:i,:),1,3);
    end
    
    xlim([0 50])
    %% Tracé du spectre d'amplitude
    plot(ax,ind(1:i,:))
    %plot_spectre2(x,data,fs,'lin',ax2);  % Tracer le spectre
    %     l = legend(ax2,'\color{white} Jour 1', sprintf('Jour %s', num2str(i)));
    %     set(l,'TextColor','white');
    %     axis(ax2,[0 fs/6 0 0.03])
    pause(0.05)
    
end
%% Tracé de l'indicateur
% ind = ind./max(ind);
%ind = sgolayfilt(ind,1,3);
% figure
% plot(ind,'--','lineWidth',0.5)
seuil = kron(ones(size(ind,1),1),5*std(ind(1:30,:)));
hold on;plot(seuil,':.','linewidth',2)

%%
healthIndicator = ind(:,1) - ind(1,1);
threshold = healthIndicator(end);

time = 1:length(healthIndicator);
estRULs2 = [];
horizon_dep = 25;
trueRULs =50:-1:1;
estRULs = [];
estRULs = trueRULs(1:horizon_dep)';
fo = fitoptions('Method','NonlinearLeastSquares','Normalize','on','Lower',-1e1*ones(1,4),'Upper',1e1*ones(1,4),'Robust','LAR');
func = fittype('a+b*exp(c*x+d)','independent','x','options',fo);
init = [-0.1 0.2 0.01 0.1];
%init = rand(1,4);
f = fit(time(1:horizon_dep)',healthIndicator(1:horizon_dep),func,'StartPoint', init);

for horizon = horizon_dep+1:50
    %f = fit(time(1:horizon)',healthIndicator(1:horizon),func,'StartPoint', init)
    
    %plot(f,time, healthIndicator,'predfunc');
    
    temp = feval(f,time);

    temp_bound = predint(f,time,0.9,'observation','off');
    
    estRULs = [interp1(healthIndicator(1:horizon),trueRULs(1:horizon),temp,'linear')];
    
    estRULs_bound = [interp1(healthIndicator(1:horizon),trueRULs(1:horizon),temp_bound,'linear')];
    
    plot(time,trueRULs,time,estRULs,time,estRULs_bound);

    xlim([0 50])
    pause(0.1);
end  
