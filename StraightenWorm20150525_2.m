% worm=stackLoad('E:\20141212\BrainScanner20141212_145951\fiducials\hiResSegmentFolder3Dtest_raw\image00500.tif');
% activity=stackLoad('E:\20141212\BrainScanner20141212_145951\fiducials\hiResActivityFolder3Dtest_raw\image00500.tif');

 dataFolder=uipickfiles;
 dataFolder=dataFolder{1};
%dataFolder='F:\20141212\BrainScanner20141212_145951\';
%[bfAll,fluorAll,hiResData]=tripleFlashAlign(dataFolder,imSize);
%%



zindexer=@(x,s) x./(s)+1;


rows=1200;
cols=600;
nPix=rows*cols;

[bfAll,fluorAll,hiResData]=tripleFlashAlign(dataFolder,[rows cols]);


    vidInfo.bfAll=bfAll;
    vidInfo.fluorAll=fluorAll;
    vidInfo.hiResData=hiResData;
    


%% load alignment data

display('Select Low Res Alignment')

lowResFluor2BF=uipickfiles('FilterSpec','Y:\CommunalCode\3dbrain\registration');
lowResFluor2BF=load(lowResFluor2BF{1});
%lowResFluor2BF=load('Y:\CommunalCode\3dbrain\registration\20141212LowResBehavior2Fluor.mat');
lowResBF2FluorT=invert(lowResFluor2BF.t_concord);


display('Select Hi to Low Fluor Res Alignment')
Hi2LowResF=uipickfiles('FilterSpec','Y:\CommunalCode\3dbrain\registration');
Hi2LowResF=load(Hi2LowResF{1});
%Hi2LowResF=load('Y:\CommunalCode\3dbrain\registration\20141212HighResS2LowResFluorBeads.mat');


% display('Select Hi to Low Res Alignment')
% 
% Hi2LowRes=uipickfiles('FilterSpec','Y:\CommunalCode\3dbrain\registration');
% Hi2LowRes=load(Hi2LowRes{1});
% t_concord = fitgeotrans(Hi2LowRes.Sall,Hi2LowRes.Aall,'projective');
 display('Select Hi Res Alignment')

S2AHiRes=uipickfiles('FilterSpec','Y:\CommunalCode\3dbrain\registration');
S2AHiRes=load(S2AHiRes{1});
%S2AHiRes=load('Y:\CommunalCode\3dbrain\registration\20141212HiResS2A.mat');
rect1=S2AHiRes.rect1;
rect2=S2AHiRes.rect2;

%%
alignments.lowResFluor2BF=lowResFluor2BF;
alignments.S2AHiRes=S2AHiRes;
alignments.Hi2LowResF=Hi2LowResF;



%% load Fiducials file
fiducialFile=dir([dataFolder filesep '*iducial*']);
fiducialFile={fiducialFile.name}';
if length(fiducialFile)~=1
        display('Select model file');

    fiducialFile=uipickfiles('FilterSpec',dataFolder);
    fiducialFile=load(fiducialFile{1});
    fiducialPoints=fiducialFile.fiducialPoints;
    z2ImageIdxOffset=fiducialFile.timeOffset;
    
else
    fiducialFile=load([dataFolder filesep fiducialFile{1}]);
    fiducialPoints=fiducialFile.fiducialPoints;
    z2ImageIdxOffset=fiducialFile.timeOffset;

end



%%

hasPoints=cellfun(@(x) ~isempty(x{1}), fiducialPoints,'uniformoutput',0);
hasPoints=find(cell2mat(hasPoints));


%%
zOffset=z2ImageIdxOffset;

startStack=hasPoints(1);
endStack=hasPoints(end);
destination= 'CLstraight_20150526';
imageFolder2=[dataFolder filesep destination];
mkdir(imageFolder2);
show=0;
stackRange= startStack+1:endStack;

pointStats=repmat(struct(),1,length(stackRange));

%% do first image in range
tic
show=1;
counter=1;
[V,pointStatsOut,Vtemplate,vRegion]=...
    WormCLStraighten_2(dataFolder,destination,vidInfo,...
    alignments,fiducialPoints{startStack},[],[],zOffset,startStack,show);
poinStatsFields=fieldnames(pointStatsOut);
for iFields=1:length(poinStatsFields)
    field=poinStatsFields{iFields};
    pointStats(counter).(field)=pointStatsOut.(field);

    
end

show=0;




display(['Finished image ' num2str(startStack,'%3.5d') ' in ' num2str(toc) 's'])

%%
subfiducialPoints=fiducialPoints(stackRange);
%parforprogress(length(stackRange)-1);
for counter=2:length(stackRange)
 %   parforprogress
%progressbar((iStack-startStack)/(endStack-startStack));
             iStack=stackRange(counter);
display(['Starting'  num2str(iStack,'%3.5d') ])
     try
          tic
%change indexing for better parfor 
         ctrlPoints=subfiducialPoints{counter};
[V,pointStatsOut,~,~]=...
    WormCLStraighten_2(dataFolder,destination,vidInfo,...
    alignments,ctrlPoints,Vtemplate,vRegion,zOffset,iStack,show);

for iFields=1:length(poinStatsFields)
    field=poinStatsFields{iFields};
    pointStats(counter).(field)=pointStatsOut.(field);

    
end




display(['Finished image ' num2str(iStack,'%3.5d') ' in ' num2str(toc) 's'])


     catch ME
        ME
        display(['Error in Frame' num2str(iStack,'%3.5d') ' in ' num2str(toc) 's'])

    end
    
    
end
save([imageFolder2 filesep 'PointsStats'],'pointStats');

%%
for iStack=startStack:endStack
    fileName4=[imageFolder2 filesep 'controlPoints' num2str(iStack,'%3.5d')];
    Fpoints2=fpointsAll{iStack};
    save(fileName4,'Fpoints2');
end





%%

for iStack=startStack:endStack
fileName2=[imageFolder2 filesep 'image' num2str(iStack,'%3.5d') '.tif'];
fileName3=[imageFolder2 filesep 'imageMap' num2str(iStack,'%3.5d') '.tif'];
wormRegions=stackLoad(fileName3);
worm=stackLoad(fileName2);
    
    
end




%%
[Fy,Fx,Fz]=gradient(im);




fx=interp3(Fx,sx,sy,sz,'*linear');
fy=interp3(Fy,sx,sy,sz,'*linear');
fz=interp3(Fz,sx,sy,sz,'*linear');

fr=nx.*fx+ny.*fy+nz.*fz;
fr=nansum(fr,2);
fx=nansum(fx,2);
fy=nansum(fy,2);
fz=nansum(fz,2);

%%








%wormSmooth=bpass3(worm,10,[20,20,15]);


