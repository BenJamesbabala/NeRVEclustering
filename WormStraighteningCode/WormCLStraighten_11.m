
function [V,pointStats,Vproj,side,xyOffset2,wormBW2]=WormCLStraighten_11...
    (dataFolder,destination,vidInfo,alignments,Vtemplate,zOffset,iStack,side,show)

% takes data for whole brain imaging set, centerlines, himag movies, lowmag
% behavior videos to create straighten worm in given frame
%adding second part to straighten.

%Ver 11, trying to make straightening better with some feedback

%% initial parameters
%size to search around centerline
outputRadius=83.5;
outputRadiusZ=63.5;
outputRadiusBuff=30;
outputLengthBuff=100;
outputLength=200;

%ratio between xypixels and z slices
zRatio=1/3;
zindexer=@(x,s) x./(s)+1;
options.method='invdist';
options.radius=20;
options.power=1;
options.thresh1=.05;
options.minObjSize=50;
options.maxObjSize=400;
options.minSphericity=.80;
options.filterSize=[10 10 4];
options.power=1;
options.prefilter=1;
options.hthresh=0;



imageFolder2=[dataFolder filesep destination];
%% set up different kernals
%gaussians
gaussKernal2=gausswin(200);
gaussKernal2=convnfft(gaussKernal2,gaussKernal2');

%mexican hat filters
Sfilter=max(gaussKernal2(:))-gaussKernal2;
Sfilter(Sfilter<.1)=-(.1-Sfilter(Sfilter<.1))*80;

Sfilter(Sfilter>.8)=0;
Sfilter(Sfilter>0)=1;

Sfilter2=max(gaussKernal2(:))-gaussKernal2;
Sfilter2(Sfilter2<.01)=Sfilter2(Sfilter2<.01)-.3;
Sfilter2(Sfilter2>.6)=0;

Sfilter2(Sfilter2>0)=nnz(Sfilter2<0)/nnz(Sfilter2>0);
Sfilter2=Sfilter2-mean(Sfilter2(:));





%% recover alignments
lowResFluor2BF=alignments.lowResFluor2BF;
S2AHiRes=alignments.S2AHiRes;
Hi2LowResF=alignments.Hi2LowResF;
rect1=S2AHiRes.rect1;

%% set up low fluor video to assist centerline centering

aviFiles=dir([dataFolder filesep '20*.avi']);
aviFiles={aviFiles.name}';
aviFiles=aviFiles(cellfun(@(x) isempty(strfind(x,'HUDS')),aviFiles));

d= dir([dataFolder filesep 'LowMagBrain*']);
if ~isempty(d)
    aviFolder=[dataFolder filesep d(1).name];
end
if length(aviFiles)==2
    aviFluorIdx=cellfun(@(x) ~isempty(strfind(x,'fluor')),aviFiles);
    fluorMovie=[dataFolder filesep aviFiles{aviFluorIdx}];
elseif isdir(aviFolder)
    fluorMovie=[aviFolder filesep 'cam0.avi'];
else
    
    display('Select avi files,low mag fluor');
    movies=uipickfiles('FilterSpec',dataFolder);
    fluorMovie=movies{1};
end

fluorVidObj= VideoReader(fluorMovie);

%% set up high mag videos
if isempty(vidInfo)
    
    [bfAll,fluorAll,hiResData]=tripleFlashAlign(dataFolder);
else
    bfAll=vidInfo.bfAll;
    fluorAll=vidInfo.fluorAll;
    hiResData=vidInfo.hiResData;
    
end
%% set up timing alignments and lookups using interpolation
bfIdxList=1:length(bfAll.frameTime);
fluorIdxList=1:length(fluorAll.frameTime);
bfIdxLookup=interp1(bfAll.frameTime,bfIdxList,hiResData.frameTime,'linear');
fluorIdxLookup=interp1(fluorAll.frameTime,fluorIdxList,hiResData.frameTime,'linear');


%% load centerline
%get behavior folder
behaviorFolder=dir([dataFolder filesep 'Behavior*']);
behaviorFolder=behaviorFolder([behaviorFolder.isdir]);
behaviorFolder=[dataFolder filesep behaviorFolder(1).name];

%in behavior folder, get centerline file
centerlineFile=dir([behaviorFolder filesep 'center*']);
centerlineFile=[behaviorFolder filesep centerlineFile(1).name];

%load centerline file and make variables based on field names
centerline=load(centerlineFile);
CLfieldNames=fieldnames(centerline);
CLfieldIdx=cellfun(@(x) ~isempty(strfind(x,'centerline')),CLfieldNames);
CLoffsetIdx=cellfun(@(x) ~isempty(strfind(x,'off')),CLfieldNames);
if any(CLoffsetIdx)
    CLoffset=centerline.(CLfieldNames{CLoffsetIdx});
else
    CLoffset=0;
end
centerline=centerline.(CLfieldNames{CLfieldIdx});


%%
try
    %% load images
    
    datFileDir=dir([dataFolder filesep 'sCMOS_Frames_U16_*']);
    datFile=[dataFolder filesep datFileDir.name];
    [rows,cols]=getdatdimensions(datFile);
    nPix=rows*cols;
    Fid=fopen(datFile);
    
    %select frames to analyze
    hiResIdx=find(hiResData.stackIdx==iStack)+ zOffset;
    %get z values of those frames
    zRange=hiResData.Z(hiResIdx-zOffset);
    zSize=length(hiResIdx);

    %get correspoinding fluor indices
    fluorIdx=round(fluorIdxLookup(hiResIdx));
    fluorIdxRange=[min(fluorIdx) max(fluorIdx)];
    
    %load up lowmag fluor image
    fluorFrame=read(fluorVidObj,fluorIdxRange);
    fluorFrame=squeeze(fluorFrame(:,:,1,:));
    %warp it to align with high mag, it warps to the uncropped high mag so
    %we need to crop it
    fluorFrame2=imwarp(fluorFrame,Hi2LowResF.t_concord,...
        'OutputView',Hi2LowResF.Rsegment);
        fluorFrame2=fluorFrame2((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),:);

        %do something with status errors!
    status=fseek(Fid,2*(hiResIdx(1))*nPix,-1);
    
    pixelValues=fread(Fid,nPix*(length(hiResIdx)),'uint16',0,'l');
    hiResImage=reshape(pixelValues,rows,cols,length(hiResIdx));
    %subtract background
    hiResImage=bsxfun(@minus, hiResImage,alignments.background);
    
    %% crop and align hi mag images
    segmentChannel=hiResImage((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),:);

    %% filter to find center Z (some old things here)
    worm2=segmentChannel;
    %3d bpass filter
    worm3=bpass3(worm2,.5,[20 20 3]);
    % additional boxcar smoothing in XY
    worm3Smooth=smooth3(worm3,'box',[15,15,1]);
    % thresholded smooth image
    segmentChannel4=normalizeRange(worm3Smooth)>.05;
    
    %% find middle plane by looking for large thresholded objects. 
    max_dist_plot=zeros(1,zSize);
    for i=1:zSize
        %for each slice, find object boundary pixels
        [midZx,midZy]=find(bwmorph(segmentChannel4(:,:,i),'remove'));
        %find max distance between those points, the slice with the largest
        %chord is the middle
        max_thresh_dist=max(pdist([midZx midZy]));
        if ~isempty(max_thresh_dist)
            max_dist_plot(i)=max_thresh_dist;
        end
    end
    %find peak in plot, corresponding with slice with largest object
    max_dist_plot=normalizeRange(max_dist_plot(:));
    [~,midZ]=max(smooth(max_dist_plot,3));
    %incase there are repeat vallues, just take the mean (rare)
    midZ=(mean(midZ));
    %round the middle plane in the direction of the middle 
    if midZ>zSize/2
        midZ=floor(midZ);
    else
        midZ=ceil(midZ);
    end
    %dont let middle plane be one of the end planes.
    if midZ==1
        midZ=2;
    elseif midZ>=zSize;
        midZ=zSize-1;
    end

    %% try fix centerline alignemnt by looking at lowmag fluor and finding 
    % a correction offset between the transformed lowmag fluor and the high
    % mag segmentation. 
    
    % get lowmag fluor and threshold, and project
    % cast fluor image
    fluorFrame2=normalizeRange(double(fluroFrame2));
    %apply automatic threshold and z project
    fframe_thresh=(fluorFrame2>(graythresh(fluorFrame2(:))));
    fluorProj=normalizeRange(sum(fframe_thresh,3));
    
    %remove boundary 
    boundaryRegion=ones(size(fluorProj)); 
    boundaryRegion(51:end-50,51:end-50)=0;
    fluorProj=fluorProj.*~boundaryRegion;
    
    %before boundary was only removed for this section, i think it doesnt
    %make a difference 20160712
    [fcm_x, fcm_y]=find(fluorProj==max(fluorProj));
    fcm_x=mean(fcm_x);
    fcm_y=mean(fcm_y);
    %% find offset between transformed lowmag and high mag usinng correlation
    % do the same for high mag
    hiResProj=normalizeRange(sum(segmentChannel,3));
    % z projectect raw lowmag 
    fluorProjRaw=sum(fluorFrame2,3);
    

    % do correlation to find xy offset between images, 
    corrIm=conv2(fluorProjRaw,rot90(hiResProj,2),'same');
    [CLoffsetY,CLoffsetX]=find(corrIm==max(corrIm(:)));
    CLoffsetX=CLoffsetX-round(size(fluorProj,2)/2);
    CLoffsetY=CLoffsetY-round(size(fluorProj,1)/2);
    
    %get proper centerlines to use that correspond to the hiresframes
    hires_range=min(hiResIdx):max(hiResIdx);
    CLIdx=round(bfIdxLookup(hires_range));
    CLIdx=CLIdx-CLoffset;
    % find unique terms, ia are the unique idx, ic is the mapping from the
    % output to the intput.
    [CLIdx,ia,ic]=unique(CLIdx);
    CL=centerline(:,:,CLIdx);
    %% try to fix obvious centerline errors if they're off
    %compare centerlines to median filtered centerelines, replace them if
    %they are far off
    % reshape into 2day array for median filtering
    clx=squeeze(CL(:,1,:));
    cly=squeeze(CL(:,2,:));
    clx_med=medfilt2(clx,[1,5]);
    cly_med=medfilt2(cly,[1,5]);
    
    % cl err is the squared distance from original CL and med filtered 
    cl_err=sqrt(mean((clx_med-clx).^2+(cly_med-cly).^2));
    cl_replace_idx=find(cl_err'>30 & ia>1 & ia<max(ia));
    % if distance is large, replace CL with medfiltered one. 
    CL(:,1,cl_replace_idx)=clx_med(:,cl_replace_idx);
    CL(:,2,cl_replace_idx)=cly_med(:,cl_replace_idx);
    
    
    %% transform centerlines into himag coordinates
    
    %get the centerlines, one for each hires frame, with some repeats
    CL2=CL(:,:,ic);
    %centerline from behavior coordinate system to fluor coordinate system
    [CL2f(:,2,:),CL2f(:,1,:)]=transformPointsInverse(...
        lowResFluor2BF.t_concord,CL2(:,2,:),CL2(:,1,:));
    %centerline from lowmag fluor coordinate system to himag
    [CL2(:,1,:),CL2(:,2,:)]=transformPointsForward(....
        Hi2LowResF.t_concord,CL2f(:,2,:),CL2f(:,1,:));
    %subtract the rectangle size
        CL2(:,2,:)=CL2(:,2,:)-(rect1(2)-1);
    
    
    %% interpolate to parameterize by length
    %range to interpolate from tip, in highres pixels 
    CLlengthRange=2500;
    
    CL3all=zeros(CLlengthRange,2,size(CL2,3));
    
    %reinterpolate centerline by length, with spacing appropriate for
    %higher mag coordinate system
    for iCL=1:size(CL2,3)
        CL2temp=CL2(:,:,iCL);
        %distance steps
        ds=squeeze(sqrt(sum((diff(CL2temp,[],1)).^2,2)));
        s=[0;cumsum(ds) ];
        %reinterpolate from initial distances to pixel distances
        CL2temp=interp1(s,CL2temp,1:1:CLlengthRange,'linear','extrap');
        CL2temp(:,:,iCL)=CL2temp;
        if show
            if iCL==1
                close all
                imagesc(segmentChannel(:,:,midZ))
                hold on
            end
            plot(CL2temp(:,1),CL2temp(:,2))
            scatter(CL2temp(1500,1),CL2temp(1500,2));
            drawnow
        end
        
    end
    
    %% align centerlines parameterizations by correlation
    % centerlines points can be offset to each other because nothing stops
    % them from sliding if the tips are not clear. We need to align the
    % consecutive centerlines to each other.  
    % Alignment of  centerlines using plotMatch (distance based) to account
    % for centerline sliding.
    shiftVec=zeros(1,length(ia)-1);
    for i=2:length(ia);
        %find best offset between consecutive centerlines.
        CL1temp=CL3all(:,:,ia(i));
        CL2temp=CL3all(:,:,ia(i-1));
        [corrtemp,r]=plotMatch2(CL1temp,CL2temp);
        [~,shift]=min(corrtemp);
        shiftVec(i)=r(shift);
    end
    
    % add the offsets back
    shiftVec=cumsum(shiftVec);
    shiftVec=shiftVec-shiftVec(round(length(shiftVec)/2));
    CL3all2=zeros(CLlengthRange+501,2,size(CL2,3));
    
    for iCL=1:size(CL2,3)
        CL3temp=CL3all(:,:,iCL);
        CL3temp=interp1(CL3temp,shiftVec(ic(iCL))+(-500:CLlengthRange),'linear','extrap');
        CL3all2(:,:,iCL)=CL3temp;
        if show
            if iCL==1
                close all
                imagesc(segmentChannel(:,:,midZ))
                hold on
            end
            plot(CL3temp(:,1),CL3temp(:,2))
            scatter(CL3temp(1300,1),CL3temp(1300,2),'w');
            drawnow
        end
    end
    %will crop centerline coordinates around the center of the image
    
    %%
    %this fix was added 20160328 for when the reference is not close to the
    %fluorescence in lowmagfluor.
    
    %find CL points that has brightest points in low mag fluor
    CL2f_mean=(CL2f(:,:,1));
    CL2f_I=interp2(sum(fluorFrame,3),CL2f_mean(:,2),CL2f_mean(:,1));
    [~,refIdx]=max(CL2f_I);
    %create initial offset as the shift between the high mag fluor center and
    %the index and the high mag CL point found using lowmag data
    xyOffset2=[fcm_y fcm_x]-[CL2(refIdx,1,1) CL2(refIdx,2,1)];
    
    CL2X=reshape(mean(CL3all2(:,1,1:end),3),[],1,1);
    CL2Y=reshape(mean(CL3all2(:,2,1:end),3),[],1,1);
    %%
    %shift around the centerline to optimize overlap between centerline and
    %fluorescence image
    fluorProj2=convnfft(fluorProj,Sfilter2,'same');
    fluorProj2=fluorProj2.*~boundaryRegion;
 
    fluorProj_normalize=normalizeRange(fluorProj2);
    [xyOffset2_min,~]=fminsearch(@(x) CLsearch(fluorProj_normalize,CL2X+xyOffset2(1),...
        CL2Y+xyOffset2(2),show,x),[0 0 ]);
    
    xyOffset3=xyOffset2+xyOffset2_min-[CLoffsetX CLoffsetY];
    
    %apply offsets so that centerlines better overlap with high mag images
    CL2(:,2,:)=CL2(:,2,:)+xyOffset3(2);
    CL2(:,1,:)=CL2(:,1,:)+xyOffset3(1);
    CL3all2(:,2,:)=CL3all2(:,2,:)+xyOffset3(2);
    CL3all2(:,1,:)=CL3all2(:,1,:)+xyOffset3(1);
    
    if show
        close all
        imagesc(worm2(:,:,midZ))
        hold on
        CL2X=CL2X+xyOffset3(1);
        CL2Y=CL2Y+xyOffset3(2);
        plot(CL2X,CL2Y,'xr');
    end
    
    
    
    %%
    %crop cetnerline around inImageRange
    CLcenter=sum(bsxfun(@minus, CL3all2,rect1(3:4)/2).^2,2);
    [~,CLcenter]=min(CLcenter,[],1);
    
    outputLength2=outputLength+outputLengthBuff;
    inImageRange=mean(CLcenter(:))+(-outputLength2:outputLength2);
    CL3all=interp1(CL3all2,inImageRange,'*linear','extrap');
    
    %% pickout central centerline and middle slice
    midIm=normalizeRange(mean(worm2(:,:,midZ+(-1:1)),3));
    midIm=double(midIm);
    %apply band pass filters
    midIm=bpass(midIm,2,[20,20]);
    midImS=imfilter(midIm,Sfilter);    
    
    CL3allX=(CL3all(:,1,:));
    CL3allY=(CL3all(:,2,:));
    minSearch=interp2(midImS,CL3allX,CL3allY);
    minSearch=squeeze(nansum(minSearch,1));
    minY=find(minSearch==max(minSearch));
    midZCL=round(mean(minY));
    CL_mid=CL3all(:,:,midZCL);
    
    
    %% show middle imagee with overlayed centerline
    if show
        close all
        imagesc(midIm)
        hold on
        plot(CL_mid(:,1),CL_mid(:,2),'x')
        axis equal
        hold off
        drawnow
    end
    %% make coordinate system around the worm
    Tv=zeros(size(CL3all,1),3,size(CL3all,3));
    Bv=Tv; Nv=Tv;
    for iSlice=1:size(CL3all,3);
        
        T=normr(gradient(CL3all(:,:,iSlice)',5)');
        N=[T(:,2) -T(:,1)];
        B=T(:,1).*N(:,2)-T(:,2).*N(:,1);
        N=bsxfun(@times, N,sign(B));
        B=sign(B);
        
        Tv(:,:,iSlice)=[T zeros(size(CL_mid(:,1)))];
        Nv(:,:,iSlice)=[N zeros(size(CL_mid(:,1)))];
        Bv(:,:,iSlice)=[zeros(size(CL_mid(:,1))) zeros(size(CL_mid(:,1))) B];
        
    end

    signVector=sign(Bv(:,3,:));
    Bv=bsxfun(@times,Bv,signVector);
    Nv=bsxfun(@times,Nv,signVector);
    
    %select worm orientation and fix
    if isempty(side)
        imagesc(midIm)
        choice = menu('Which Side is the nerve chord on?','Right','Left');
        if choice==2
            side='Left';
            Bv=-Bv;
            Nv=-Nv;
        else
            side='Right';
        end
    else
        if ~isempty(strfind(side,'eft'))
            Bv=-Bv;
            Nv=-Nv;
        end
    end
    
    
    
    
    plane_num=size(Tv,1);
    %make the first and last 'endround' tbn vectors the same so nothing
    %strange happens at the ends.
    if plane_num>10
        endround=5;
    else
        endround=round(plane_num/2);
    end
    for iSlice=1:size(CL3all,3);
        for i=1:endround
            Tv(plane_num-i+1,:,iSlice)=Tv(plane_num-endround+1,:,iSlice);
            Bv(plane_num-i+1,:,iSlice)=Bv(plane_num-endround+1,:,iSlice);
            Nv(plane_num-i+1,:,iSlice)=Nv(plane_num-endround+1,:,iSlice);
            Tv(i,:,iSlice)=Tv(endround,:,iSlice);
            Bv(i,:,iSlice)=Bv(endround,:,iSlice);
            Nv(i,:,iSlice)=Nv(endround,:,iSlice);
        end
    end
    
    %create a 2*window +1 square around each point for interpolationg using
    %the B and N vectors
    
    
    %% show stack with centerline
    if show
        close all
        %
        for iSlice=1:size(worm2,3);
            
            imagesc(worm2(:,:,iSlice));colormap hot
            hold on
            clSlice=iSlice;
            clSlice=round(clSlice);
            clSlice(clSlice<1)=1;
            clSlice(clSlice>size(CL3all,3))=size(CL3all,3);
            plot(CL3all(:,1,clSlice),CL3all(:,2,clSlice));
            quiver(CL3all(1:10:end,1,clSlice),CL3all(1:10:end,2,clSlice),...
                Nv(1:10:end,1,clSlice),Nv(1:10:end,2,clSlice))
            
            hold off
            axis auto equal off
            xlim([0 600]);ylim([0 600])
            %print(gcf,['Y:\Jeff\PowerPoint\New folder\MySavedPlot' num2str(iSlice,'%3.5d') ],'-dpng')
            pause(.1)
        end
    end
    
    %% straighten interpolation
    %define range
    outputRadius2=outputRadius+outputRadiusBuff;
    %make meshgrid for coordinate system
    [J,K]=meshgrid(-outputRadius2:outputRadius2,...
        -outputRadiusZ:outputRadiusZ);
    
    % build z coordinates
    zslice=bsxfun(@times,J,permute(Nv(:,3,1),[3,2,1]))*zRatio+...
        bsxfun(@times,K,permute(Bv(:,3,1),[3,2,1]))*zRatio+midZ;
    
    zLevels=((zslice(:,1,1)));
    
    %correct for non monoticity, there is occasionally an error where the z
    %values are non monotonic because of small noise or are repeated.  
    if sign(nanmean(diff(zRange)))==-1
        zRange2=unique(cummin(zRange));
        zRange2=zRange2-zRange2(midZ);
        %fix repeats
        adjusted_z=zLevels/10-zLevels(round(outputRadiusZ+1))/10;
        zInterp=interp1(zRange2,1:length(zRange2),adjusted_z);
        zInterp=flipud(zInterp);
        zLevels=flipud(zLevels);
    else
        zRange2=unique(cummax(zRange));
        zRange2=zRange2-zRange2(midZ);
        adjusted_z=zLevels/10-zLevels(round(outputRadiusZ+1))/10;
        zInterp=interp1(zRange2,1:length(zRange2),adjusted_z);
    end
    
    
    zslice=repmat(zInterp,1,2*outputRadius2+1,size(Bv,1));
    
    zLevels(zLevels<min(ia))=min(ia);
    zLevels(zLevels>size(worm2,3))=size(worm2,3);
    CL3xinterp=interp1(squeeze(CL3all(:,1,:))',zLevels,'linear')';
    CL3xinterp=permute(CL3xinterp,[2,3,1]);
    CL3yinterp=interp1(squeeze(CL3all(:,2,:))',zLevels,'linear')';
    CL3yinterp=permute(CL3yinterp,[2,3,1]);
    NvInterpx=interp1(squeeze(Nv(:,1,:))',zLevels,'linear');
    NvInterpy=interp1(squeeze(Nv(:,2,:))',zLevels,'linear');
    BvInterpx=interp1(squeeze(Bv(:,1,:))',zLevels,'linear');
    BvInterpy=interp1(squeeze(Bv(:,2,:))',zLevels,'linear');
    
    xslice=bsxfun(@times,J,permute(NvInterpx,[1,3,2]))+...
        bsxfun(@times,K,permute(BvInterpx,[1,3,2]));
    xslice=bsxfun(@plus, xslice,CL3xinterp);
    yslice=bsxfun(@times,J,permute(NvInterpy,[1,3,2]))+...
        bsxfun(@times,K,permute(BvInterpy,[1,3,2]));
    yslice=bsxfun(@plus, yslice,CL3yinterp);
    
    xslice=permute(xslice,[3,2,1]);
    yslice=permute(yslice,[3,2,1]);
    zslice=permute(zslice,[3,2,1]);
    
    %%
    %use points to interpolate, XY in matlab is messed me up.. but this
    %works
    %if using gradient, convolve stack with sobel operator in each
    %direction and find magnitude
    
    %       if 1%~cline_para.gradflag
    
    xslice=round(xslice);yslice=round(yslice);zslice=round(zslice);
    inImageMap=xslice>0 & zslice>0 & yslice>0 & xslice<size(worm2,2) &...
        yslice<size(worm2,1) &  zslice<size(worm2,3);
    inImageMapIdx=sub2ind_nocheck(size(worm2),(yslice(inImageMap)),...
        (xslice(inImageMap)),(zslice(inImageMap)));
    V=zeros(size(xslice));
    V(inImageMap)=worm2(inImageMapIdx);
    Vproj=sum(V,3);
    
    
    
    %% stack stabilization
    
    [~, tformAll]=stackStabilization(V,30,show,0);
    R = imref2d(size(V(:,:,1))) ;
    for iSlice=1:size(xslice,3)
        if any(any(inImageMap(:,:,iSlice)))
            temp=imwarp(cat(3,xslice(:,:,iSlice),yslice(:,:,iSlice)),...
                R,tformAll{iSlice},'nearest','OutputView',R);
            xslice(:,:,iSlice)=temp(:,:,1);
            yslice(:,:,iSlice)=temp(:,:,2);
            
        end
    end
    
    xslice=round(xslice);yslice=round(yslice);zslice=round(zslice);
    inImageMap=xslice>0 & zslice>0 & yslice>0 & xslice<size(worm3,2) &...
        yslice<size(worm3,1) &  zslice<size(worm3,3);
    inImageMapIdx=sub2ind(size(worm3),(yslice(inImageMap)),...
        (xslice(inImageMap)),(zslice(inImageMap)));
    Vsmooth=zeros(size(xslice));
    V=Vsmooth;
    Vsmooth(inImageMap)=worm3(inImageMapIdx);
    V(inImageMap)=worm2(inImageMapIdx);
    
    %%
    
    
    Vproj=squeeze(nansum(V,3));
    
    
    %% Correlation algin with template image
    
    if ~isempty(Vtemplate)
        % repalced xcorr with conv2 for small speed boost, search area is decreased
        xIm=conv2(Vproj,rot90(Vtemplate,2),'same');
        [xlag,ylag]=find(xIm==max(xIm(:)));
        lags=[xlag,ylag]-round(size(Vproj)/2);
    else
        lags=[0 0];
    end
    %%
    [ndX,ndY,ndZ]=ndgrid(1:size(V,1),1:size(V,2),1:size(V,3));
    ndX=ndX+lags(1);
    ndY=ndY+lags(2);
    
    ndX=round(ndX);ndY=round(ndY);
    inImage=(ndY>0 & ndX>0 & ndX<(outputLength+outputLength2+1) & ndY<((outputRadius2+outputRadius)+1));
    inImageIdx=sub2ind_nocheck(size(V),ndX(inImage),ndY(inImage),ndZ(inImage));
    temp=zeros(size(V));
    temp(inImage)=V(inImageIdx);
    temp2=temp(outputLengthBuff+1:end-outputLengthBuff,outputRadiusBuff+1:end-outputRadiusBuff,:);
    V=temp2;
    temp(inImage)=xslice(inImageIdx);
    temp2=temp(outputLengthBuff+1:end-outputLengthBuff,outputRadiusBuff+1:end-outputRadiusBuff,:);
    xslice=temp2;
    temp(inImage)=yslice(inImageIdx);
    temp2=temp(outputLengthBuff+1:end-outputLengthBuff,outputRadiusBuff+1:end-outputRadiusBuff,:);
    yslice=temp2;
    temp(inImage)=zslice(inImageIdx);
    temp2=temp(outputLengthBuff+1:end-outputLengthBuff,outputRadiusBuff+1:end-outputRadiusBuff,:);
    zslice=temp2;
    temp(inImage)=Vsmooth(inImageIdx);
    temp2=temp(outputLengthBuff+1:end-outputLengthBuff,outputRadiusBuff+1:end-outputRadiusBuff,:);
    Vsmooth=temp2;
    
    
    Vproj=squeeze(nansum(V,3));
    
    
    
    
    
    
    
    %% now segmentation
    
    V(isnan(V))=0;
    Vsmooth(isnan(Vsmooth))=0; % option, to use presmoothed version, much faster but may not be a s good
    imsize=size(V);
    [wormBW2,~]=WormSegmentHessian3dStraighten(V,options,Vsmooth);
    %%
    BWplot=(squeeze(sum(sum(wormBW2,1),2)));
    BWplot=smooth(BWplot,20);
    [~,locs]=findpeaks(BWplot);
    endpts=locs([1,length(locs)]);
    [~,locs]=findpeaks(-BWplot);
    botpoint1=locs((locs>endpts(1)));
    if isempty(botpoint1);botpoint1=1;end;
    botpoint1=botpoint1(1);
    botpoint2=locs((locs<endpts(2)));
    if isempty(botpoint2);botpoint2=imsize(3);end;
    
    botpoint2=botpoint2(end);
    botpoint1(botpoint1>imsize(3)*1/4)=1;
    botpoint2(botpoint2<imsize(3)*3/4)=imsize(3);
    
    
    cc=bwconncomp(wormBW2,6);
    
    badRegions=(cellfun(@(x) any(zindexer(x,imsize(1)*imsize(2))<=botpoint1),cc.PixelIdxList)...
        |cellfun(@(x) any(zindexer(x,imsize(1)*imsize(2))>=botpoint2),cc.PixelIdxList))';
    
    wormBW2(cell2mat(cc.PixelIdxList(badRegions)'))=false;
    cc.PixelIdxList=cc.PixelIdxList(~badRegions);
    cc.NumObjects=nnz(~badRegions);
    %hard cap at 200 neurons, occasionally  you have big fails that produce
    %many hundreds of points. this is bad, just blank everything if this
    %happens
    if cc.NumObjects<200
        cc=bwconncomp(wormBW2,6);
        stats=regionprops(cc,V,'Centroid','MeanIntensity',...
            'Area');
        
        intensities=[stats.MeanIntensity]';
        P=[cell2mat({stats.Centroid}'),iStack*ones(cc.NumObjects,1)...
            (1:cc.NumObjects)'  intensities];
        P(:,[1 2])=P(:,[2 1]);
        Areas=[stats.Area]';
        Poriginal=[interp3(xslice,P(:,2),P(:,1),P(:,3)) ...
            interp3(yslice,P(:,2),P(:,1),P(:,3)) ...
            interp3(zslice,P(:,2),P(:,1),P(:,3))];
        pointStats.straightPoints=P(:,1:3);
        pointStats.rawPoints=Poriginal;
        pointStats.pointIdx=(1:cc.NumObjects)';
        pointStats.Rintensities=intensities;
        pointStats.Volume=Areas;
        
    else
        pointStats.straightPoints=[];
        pointStats.pointIdx=[];
        pointStats.Rintensities=[];
        pointStats.Volume=[];
        pointStats.rawPoints=[];
    end
    pointStats.stackIdx=iStack;
    
    pointStats.baseImg=logical(wormBW2);
    pointStats.transformx=uint16(xslice);
    pointStats.transformy=uint16(yslice);
    pointStats.transformz=uint16(zslice);
    %   pointStats(counter).Gintensities=intensities;
    
    
    
    %%
    
    %TrackData{counter}=P;
    fileName2=[imageFolder2 filesep 'image' num2str(iStack,'%3.5d') '.tif'];
    fileName3=[imageFolder2 filesep 'pointStats' num2str(iStack,'%3.5d')];
    if show>1
        fileName4=[imageFolder2 filesep 'saveFile' num2str(iStack,'%3.5d')];
        save(fileName4,'CL3all2', 'CL3all','Tv','Bv','Nv','worm2','V','Vsmooth','pointStats');
    end
    %tiffwrite(fileName,Vproj,'tif');
    tiffwrite(fileName2,single(V),'tif');
    save(fileName3,'pointStats');
    %save with compression reduces file size by more than 70%
    %save(fileName3,'wormRegions');
    fclose(Fid);
catch me
    fileName=[imageFolder2 filesep 'ERROR' num2str(iStack,'%3.5d')];
    save(fileName,'me');
end
