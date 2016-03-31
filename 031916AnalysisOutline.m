% for fish range, 
range_fish = [8,9,10,11];

% get 50% cell selection

% full itr. clustering

% save to VAR: all saved to VAR(i).ClusGroup{1,3}(1)

% (need to update full clustering method before cross-validation within fish)

%%
% ---- multi-fish analysis ----

%% prep
% need to interpolate data to account for different scanning speeds???!!!!!!!


%% regression

% get stim and motor regressors
% motor: L/R/F, full length data
% stim: use regressor and data for given stimlus range only
% (use stimset or manually code matching reg across fish??)

% e.g.:
% stim_range = [2,3];
% regchoice = {1,stim_range};

regchoice = {2,1};

if regchoice{1}==1, % stim Regressor
%     fishset = getappdata(hfig,'fishset');
    fishset = 2;
    regressors = GetStimRegressor(stim,fishset);
    if length(regchoice{2})>1,
        regressor = zeros(length(regchoice{2}),length(regressors(1).im));
        for i = 1:length(regchoice{2}),
            regressor(i,:) = regressors(regchoice{2}(i)).im;
        end
    else
        regressor = regressors(regchoice{2}).im;
    end
    
elseif regchoice{1}==2, % motor Regressor
    behavior = getappdata(hfig,'behavior');
    regressors = GetMotorRegressor(behavior);
    regressor = regressors(regchoice{2}).im;
end
    
% regression
thres_reg = 0.4;
isCentroid = 1;
[cIX,gIX,wIX] = f.Regression_Direct(hfig,thres_reg,regressor,isCentroid);
  
%%
figure(hfig)
f.pushbutton_loadCurrentClustersfromworkspace_Callback(hObject);

%% 
M = getappdata(hfig,'M');
CellXYZ = getappdata(hfig,'CellXYZ');
M = getappdata(hfig,'M');
BasicPlotMaps(cIX,gIX,M,CellXYZ,photostate,anat_yx,anat_yz)

% screen clusters for given regressor
% need to pass 2 thres: corr coeff and top percentage?? (need to hand-tune)

% -- between 2 fish --
% compare anatomical location:
% for given screened cluster, is there another screened cluster anatomically close
% (anatomically close defined as cluster centroids distance below
% threshold, and difference in distributedness below threshold)
% save selected pairs/multiple clusters
% output percentage of "conserved" clusters
% -- get average percentage for all pairs of fish --

% -- multi-fish clustering --
% or, plot clusters for all fish for given regressor onto standard brain,
% and cluster centroid location and distributedness; this "conserved"
% cluster needs to span multiple fish, ideally all fish

%% other clusters ((spontaneous))

% like above, find anatomically similar candidate clusters, and 
% plot out their activity traces
% select by hand
% save selected pairs/multiple clusters
