function [fig1,fig2] = MultiMotorVisuals(hfig,stimcorr,motorcorr,cIX_in,gIX_in)
isScaleClrToRange = 0;

%% get coefficients from multiple linear regression

% figure;scatter(stimcorr,motorcorr)%scatter(motorcorr,stimcorr)

%% draw custom 2-D colormap illustration (square)
% res = 100;
% grad = linspace(0,1,res);
% rev_grad = linspace(1,0,res);
% 
% grid = ones(res,res,3);
% 
% grid(:,:,3) = repmat(grad,res,1)';
% grid(:,:,1) = 0.5*repmat(rev_grad',1,res)'+0.5*repmat(rev_grad,res,1)';
% grid(:,:,2) = repmat(grad',1,res)';
% 
% clrmap_2D = reshape(grid,res*res,3);
% 
% % figure;imagesc(grid)
% % axis xy
% % axis off
% % axis equal
[grid, res] = MakeDiagonal2Dcolormap;

% [plot scaled 2D-colorbar?]

% figure;imagesc(grid)
% axis xy
% axis equal


%% get new gIX with matching custom colormap 'cmap_U'
if false % temp, trying this for cell-based betas
    thres_stim = prctile(stimcorr,90);
    thres_motor = prctile(motorcorr,90);
    IX_stim = find(stimcorr>thres_stim);
    IX_motor = find(motorcorr>thres_motor);
    stimcorr(IX_stim) = thres_stim;
    motorcorr(IX_motor) = thres_motor;
end

%%
clrmap = MapXYto2Dcolormap(gIX_in,stimcorr,motorcorr,[0,1],[0,1],grid);

gIX2 = SqueezeGroupIX(gIX_in);
U = unique(gIX2);
U_size = zeros(size(stimcorr));
% clrmap = zeros(length(clrIX_x),3);
% clrmap_2D = reshape(grid,res*res,3); % for efficient indexing

for i = 1:length(U)
    ix = find(gIX2 == U(i));
    U_size(i) = length(ix);
%     ix = sub2ind([res,res],clrIX_y(U(i))',clrIX_x(U(i))');
%     clrmap(i,:) = clrmap_2D(ix,:);
end

%% bubble plot in 2-D color (plot of all clusters, cluster size indicated by circular marker size) 
fig1 = figure('Position',[500,500,300,250]);
scatter(stimcorr,motorcorr,U_size,clrmap)
xlabel('stimulus corr.');ylabel('motor corr.');

if ~isScaleClrToRange
    axis equal
    xlim([0,1]);
    ylim([-0.3,1]);
%     set(gca,'YTick',-0.2:0.2:0.6);
end

%% Anat plot with custom colormap
% isRefAnat = 1;
% isPopout = 1;
fig2 = figure('Position',[800,200,700,1000]);
% DrawCellsOnAnatProj(hfig,isRefAnat,isPopout,cIX_in,gIX_in,clrmap);
% DrawCellsOnAnatProj_othercolor(hfig,cIX_in,gIX_in,cmap_U,isRefAnat,isPopout);
opts = [];
opts.isShowFishOutline = true;
opts.isPopout = true;
I = LoadCurrentFishForAnatPlot(hfig,cIX_in,gIX_in,clrmap,[],opts);
DrawCellsOnAnat(I);