%%%%%%%%%%%%%%%
%%
if true,
    clear all;close all;
    varList = {'CR_dtr','nCells','CInfo','anat_yx','anat_yz','anat_zx','ave_stack','fpsec'};%,'frame_turn'};
else
    % or without 'CR_dtr', keeping it from previous step:
    clearvars -except 'CR_dtr';
    varList = {'nCells','CInfo','anat_yx','anat_yz','anat_zx','ave_stack','fpsec'};%,'frame_turn'};
end

%%
M_dir = GetFishDirectories();
M_stimset = [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2];

save_dir = GetCurrentDataDir();

dshift = 2; % differential shift between fictive and fluo, manually chosen
        
isNeedfliplr = true;
%% MANUAL
for i_fish = 11, %:8,
    disp(num2str(i_fish));
    tic
    %% load data
    datadir = M_dir{i_fish};
    load(fullfile(datadir,['Fish' num2str(i_fish) '_direct_load_nodiscard.mat']),varList{:});
    load(fullfile(datadir,'frame_turn.mat'),'frame_turn');
    
    if size(frame_turn,1)<size(frame_turn,2),
        frame_turn = frame_turn';
    end    
    
    %% for old directloads (? 8/26/2015, fish#<11)Flip correction from original data
    if isNeedfliplr,
        ave_stack = fliplr(ave_stack);
        anat_yx = fliplr(anat_yx);
        anat_zx = fliplr(anat_zx);
        
        % CInfo = cell info, need to correct indices too
        [s1,s2,~] = size(ave_stack);
        for i_cell = 1:length(CInfo),
            % fix '.center'
            CInfo(i_cell).center(2) = s2-CInfo(i_cell).center(2)+1;
            % fix '.inds'
            IX = CInfo(i_cell).inds;
            [I,J] = ind2sub([s1,s2],IX);
            J = s2-J+1;
            CInfo(i_cell).inds = sub2ind([s1,s2],I,J);
            % fix '.x_minmax'
            CInfo(i_cell).x_minmax(1) = s2-CInfo(i_cell).x_minmax(1)+1;
            CInfo(i_cell).x_minmax(2) = s2-CInfo(i_cell).x_minmax(2)+1;
        end
    end
    
    %% for old directloads <9/2/15
    temp = [CInfo(:).center];
    XY = reshape(temp',[],length(CInfo))';
    IX_discardedge = find(XY(:,1)<15 | XY(:,1)> size(ave_stack,1)-15 ...
        | XY(:,2)<15 | XY(:,2)> size(ave_stack,2)-15);
    CInfo(IX_discardedge) = [];
    CR_dtr(IX_discardedge,:) = [];    

    temp = fullfile(datadir,['Fish' num2str(i_fish) '_direct_load_nodiscard.mat']);
    save(temp,'IX_discardedge','-v7.3','-append');
    
    %% Manual occasional frame corrections: ONLY RUN ONCE!!!!!!!!!
    
    if false,
        % add 1 frame at start: ------------- for which fish again??
        CR_dtr = horzcat(CR_dtr(:,1),CR_dtr);
        frame_turn = vertcat(frame_turn(1,:),frame_turn);
    end

    % correction of an error in Fish #1
    if i_fish == 1,
        CR_dtr = horzcat(CR_dtr(:,1:20),CR_dtr);
    end
    
    %% index processing
    if M_stimset(i_fish)==1, % fish 1-7
        M_period = {480,160,160,320,480,280,300}; %,{120,150,360}};
        periods = M_period{i_fish};
        period = periods;
        
        nrep = floor(size(CR_dtr,2)/period)-1;

        shift = period; % (fixed 9/23/15; before = period+dshift)
        
        IX_all = 1+shift:period*nrep+shift;
        CellResp = CR_dtr(:,IX_all); % old name: CRZt, 'Cell Responses Zscore trimmed'
        
        nCells = size(CR_dtr,1);
        CellRespAvr = mean(reshape(CR_dtr(:,IX_all+dshift),nCells,period,[]),3); % 'Cell Response Average Zscore'
        
        if i_fish<6,
            stimrangenames = {'16 permut: B/W/phototaxis*2'};
        else % i_fish = 6 or 7
            stimrangenames = {'phototaxis'};
        end
        %         stimrangenames = {'rep average','all reps','rep #1','rep #2','last rep'};
        ix_avr = 1:period;
        ix_all = 1:period*nrep;
        tlists = {ix_avr, ix_all};
        for i = [1,2,nrep],
            ix = 1+period*(i-1):period*i;
            tlists = [tlists, ix];
        end
        
        stim_full = frame_turn(IX_all,17)';
        stim_full = round(stim_full);
        
        stimAvr = stim_full(1:period);
        
    else % multiple protocols                
        % process raw stimulus code
        [stimset,stim_full_raw] = StimulusKeyPreprocessing(frame_turn,i_fish);
                
        %% variables to save later in struct
        periods = [stimset.period];
        stimrangenames = {stimset.name};

        %% find time-lists = list of time-frames numbers for a certain stimulus
        nTypes = length(stimset);
        tlists_raw = cell(1,nTypes+1); % time-lists, i.e. frame indices
        IX_all = [];
        for i_type = 1:nTypes,
            nSets = length(stimset(i_type).starts);
            IX = [];
            for i_set = 1:nSets,
                IX = horzcat(IX,stimset(i_type).starts(i_set):stimset(i_type).stops(i_set));
            end
            tlists_raw{i_type} = IX;
            IX_all = horzcat(IX_all,IX);
        end
        tlists_raw{nTypes+1} = IX_all;
%         tlists_raw{nTypes+2} = sort(IX_all);
        
        % This is the main data to store and load to GUI
        CellResp = CR_dtr(:,IX_all); % old name: CRZt, 'Cell Responses Zscore trimmed'
        stim_full = stim_full_raw(IX_all);
        
        %% get tlists corresponding to IX_all (tlists_raw ~ 1:totalframe#)
        tlists = cell(1,nTypes+1); % time-lists, i.e. frame indices
        for i_type = 1:nTypes+1,
            [~,IX] = ismember(tlists_raw{i_type},IX_all);
            tlists{i_type} = IX(find(IX));
        end
        
        %% find average
        numcell = size(CR_dtr,1);
        shift = -dshift; % circshift fluo left by 2 frames
        
        CellRespAvr = []; % 'Cell Response Average Zscore'
        stimAvr = [];
        for i = 1:nTypes,
            M = circshift(CellResp(:,tlists{i}),shift,2);
            CellRespAvr = horzcat(CellRespAvr,mean(reshape(M,numcell,periods(i),[]),3));
            % stim from stim_full
            m = stim_full(tlists{i});
            stimAvr = horzcat(stimAvr,m(1:periods(i)));
        end

    end
    
    %% prepare fictive data
    rows = [7,8,9,13,14];
    F = frame_turn(:,rows)';
    
    F(2,:) = -F(2,:);
    Fictive = F(:,IX_all);
    
    % find averages
    if M_stimset(i_fish)==1, % fish 1-7
        FictiveAvr = mean(reshape(Fictive,length(rows),period,[]),3);
    else
        FictiveAvr = [];
        for i = 1:nTypes,
            avr = mean(reshape(F(:,tlists_raw{i}),length(rows),periods(i),[]),3);
            FictiveAvr = horzcat(FictiveAvr,avr);
        end
    end
    
    % normalizations
    for i = 1:3,
        m = FictiveAvr(i,:);
        FictiveAvr(i,:) = (m-min(m))/(max(m)-min(m));
        m = Fictive(i,:);
        Fictive(i,:) = (m-min(m))/(max(m)-min(m));
    end
    m = FictiveAvr(4:5,:);
    FictiveAvr(4:5,:) =  (m-min(min(m)))/(max(max(m))-min(min(m)));
    m = Fictive(4:5,:);
    Fictive(4:5,:) =  (m-min(min(m)))/(max(max(m))-min(min(m)));
    
    
    %% compile CONST
    CONST = [];
    names = {'ave_stack','anat_yx','anat_yz','anat_zx','CInfo','periods','shift','dshift',...
        'CellResp','CellRespAvr','Fictive','FictiveAvr','stim_full','stimAvr',...
        'tlists','stimrangenames'};
    if M_stimset(i_fish) > 1,
        names = [names,{'tlists_raw','stimset'}];
    end
    
    for i = 1:length(names), % use loop to save variables into fields of CONST
        eval(['CONST.',names{i},'=', names{i},';']);
    end
    
    %% and save
    %%% old method:
    %     temp = whos('CONST');
    %     if [temp.bytes]<2*10^9,
    %         save(['CONST_F' num2str(i_fish) '.mat'],'CONST');
    %         beep;
    %     else
    %         save(['CONST_F' num2str(i_fish) '.mat'],'CONST','-v7.3');
    %         beep;
    %     end
    
    %%% new method with partitioning of main data
    newfishdir = fullfile(save_dir,['CONST_F' num2str(i_fish) '_fast.mat']);
    const = CONST;
    const = rmfield(const,'CellResp');
    dimCR = size(CONST.CellResp);
    save(newfishdir,'const','dimCR','-v6');
    % custom function:
    SaveFileInPartsAppendv6(newfishdir,CellResp);

    toc; beep
    
end

%% initialize VAR (once)


%% Initialize VARS % outdated? Clusgroup?

% nCells = length(CONST.CInfo);
% 
% cIX = (1:nCells)';
% i = 1;
% VAR(i_fish).Class(i).name = 'all processed';
% VAR(i_fish).Class(i).cIX = cIX;
% VAR(i_fish).Class(i).gIX = ones(length(cIX),1);
% VAR(i_fish).Class(i).numel = nCells;
% VAR(i_fish).Class(i).numK = 1;
% VAR(i_fish).Class(i).datatype = 'std';
% 
% cIX = (1:100:nCells)';
% VAR(i_fish).ClusGroup{1,1}.name = 'test';
% VAR(i_fish).ClusGroup{1,1}.cIX = cIX;
% VAR(i_fish).ClusGroup{1,1}.gIX = ones(length(cIX),1);
% VAR(i_fish).ClusGroup{1,1}.numel = length(cIX);
% VAR(i_fish).ClusGroup{1,1}.numK = 1;
% 
% %%
% cIX = (1:10:nCells)';
% VAR(i_fish).ClusGroup{1,1}(12).name = '1/10 of all';
% VAR(i_fish).ClusGroup{1,1}(12).cIX = cIX;
% VAR(i_fish).ClusGroup{1,1}(12).gIX = ones(length(cIX),1);
% VAR(i_fish).ClusGroup{1,1}(12).numel = length(cIX);
% VAR(i_fish).ClusGroup{1,1}(12).numK = 1;

%% varience/std for reps for each cell
%     if i_fish==2 || i_fish==3 || i_fish==6,
%         period_real = period/2;
%     else
%         period_real = period;
%     end
%     nrep_real = floor((size(CR,2)-shift)/period_real);
%     while period_real*nrep_real+shift>size(CR,2),
%         nrep_real = nrep_real-1;
%     end
%     CRZ_3D = reshape(CRZ(:,1+shift:period_real*nrep_real+shift),nCells,period_real,[]);
%     %% updated method, weighing both std between each rep and (summed with) std of 1st half & 2nd half of experiment - 1/8/15
%     % CRZ = CONST.M_array.CellResp;
%     % if i_fish==2 || i_fish==3 || i_fish==6,
%     %     period_real = CONST.M_array.period/2;
%     % else
%     %     period_real = CONST.M_array.period;
%     % end
%     % CRZ_3D = reshape(CRZ,size(CRZ,1),period_real,[]);
%     % divide = round(size(CRZ_3D,3)/2);
%     % CRZ_std1 = std(CRZ_3D(:,:,1:divide),0,3);
%     % CRZ_std2 = std(CRZ_3D(:,:,divide+1:end),0,3);
%     % temp1 = mean(CRZ_std1,2);
%     % temp2 = mean(CRZ_std2,2);
%     %
%     % temp12 = horzcat(temp1,temp2);
%     % temp = mean(temp12,2)+std(temp12,0,2);
%     % [~,I] = sort(temp);
%     % M = temp(I);
%     % figure;plot(M)
%     %
%     % figure;imagesc(CRZ(I,:))
%     %
%     % nCells = size(CRZ,1);
%
%     %% find low variance / stimulus-locked cells
%     CRZ_std = std(CRZ_3D,0,3);
%     temp = mean(CRZ_std,2);
%
%     % find mean-std thres: 0.5
%     [~,I] = sort(temp);
%     M = temp(I);
%     figure;plot(M)
%     %%
%     i_last = length(VAR(i_fish).Class);
%     M_perc = [0.025,0.1,0.3];
%     for j = 1:length(M_perc);
%         thres = M(round(nCells*M_perc(j)));
%         cIX = find(temp<thres);
%         i = j+i_last;
%         VAR(i_fish).Class(i).round = 0;
%         VAR(i_fish).Class(i).name = ['perc < ' num2str(M_perc(j)*100) '%'];
%         %     VAR(i_fish).Class(i).notes = ['perc < ' num2str(M_perc(j)*100) '%'];
%         VAR(i_fish).Class(i).cIX = cIX;
%         VAR(i_fish).Class(i).gIX = ones(length(cIX),1);
%         VAR(i_fish).Class(i).numel = length(cIX);
%         VAR(i_fish).Class(i).numK = 1;
%         VAR(i_fish).Class(i).datatype = 'std';
%     end
%
%     %% shift CR?
%     % shift = 161;
%     % nrep=floor(size(CR,2)/period)-1;
%     %
%     % skiplist=[];
%     % IX_rep=setdiff(1:nrep, skiplist);
%     % IX=zeros(period*length(IX_rep),1);
%     %
%     % for i=1:length(IX_rep)
%     %     IX(period*(i-1)+1:period*i)=period*(IX_rep(i)-1)+1+shift:period*(IX_rep(i))+shift;
%     % end
%     %
%     % % cell_resp=cell_resp(:,1:nrep*period);
%     % CRA=mean(reshape(CR(:,IX),[nCells,period,length(IX_rep)]),3);
%     % CRAZ = zscore(CRA')';
%
