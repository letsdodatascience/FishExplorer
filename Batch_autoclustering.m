% batch run full-clustering on all fish

% f.pushbutton_autoclus_Callback

global hm1;
hObject = hm1;

data_masterdir = GetCurrentDataDir();

range_fish = [10,11,12,13];
M_ClusGroup = [2,2,2,2];
M_Cluster = [2,2,2,2];
%%
for i = 1:length(range_fish),
    i_fish = range_fish(i)
    i_ClusGroup = M_ClusGroup(i);
    i_Cluster = M_Cluster(i);
    Cluster = VAR(i_fish).ClusGroup{i_ClusGroup};
    
    numK = Cluster(i_Cluster).numK;
    gIX = Cluster(i_Cluster).gIX;
    % convert absolute index to index used for this dataset
    cIX_abs = Cluster(i_Cluster).cIX_abs;
    [~,cIX] = ismember(cIX_abs,absIX);
    setappdata(hfig,'cIX',cIX);
    
    % load time series (hdf5 file)
    data_dir = fullfile(data_masterdir,['subject_' num2str(i_fish)]);
    
    hdf5_dir = fullfile(data_dir,'TimeSeries.h5');
    CellResp = h5read(hdf5_dir,'/CellResp');
    CellRespZ = h5read(hdf5_dir,'/CellRespZ');
    CellRespAvr = h5read(hdf5_dir,'/CellRespAvr');
    CellRespAvrZ = h5read(hdf5_dir,'/CellRespAvrZ');
    absIX = h5read(hdf5_dir,'/absIX');

    setappdata(hfig,'CellResp',CellResp);
    setappdata(hfig,'CellRespZ',CellRespZ);
    setappdata(hfig,'CellRespAvr',CellRespAvr);
    setappdata(hfig,'CellRespAvrZ',CellRespAvrZ);
    setappdata(hfig,'absIX',absIX);
    toc
    
    %% load 'data'
    mat_dir = fullfile(data_dir,'data_full.mat');
    load(mat_dir,'data'); % struct with many fields
    names = fieldnames(data); % cell of strings
    for i = 1:length(names),
        setappdata(hfig,names{i},eval(['data.',names{i}]));
    end
    
    %%
    periods = getappdata(hfig,'periods');
    setappdata(hfig,'stimrange',1:length(periods));
    UpdateTimeIndex(hfig);

%%
    f.UpdateIndices(hfig,cIX,gIX,numK);
    
    %%
    tic
    pushbutton_autoclus_Callback(hObject,f,i_fish);
    toc
end