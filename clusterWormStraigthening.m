function clusterWormStraigthening(dataFolder,nStart,nRange)
% calls worm straightening code if a startWorkspace.mat file is already
% created in the dataFolder being analyzed, program runs to straighten
% stacks nStart:nStart+nRange-1


%% load initial variables
straightenData=load([dataFolder filesep 'startWorkspace.mat']);

destination=straightenData.destination;
Vtemplate=straightenData.Vtemplate;
zOffset=straightenData.zOffset;
side=straightenData.side;
vidInfo=straightenData.vidInfo;

%% load alignments
alignments=load([dataFolder filesep 'alignments']);
alignments=alignments.alignments;


display(dataFolder)
imageFolder2=[dataFolder filesep destination];

for iStack=nStart:(nStart+nRange-1)
    %set up image and pointstats names
    fileName2=[imageFolder2 filesep 'image' num2str(iStack,'%3.5d') '.tif'];
    fileName3=[imageFolder2 filesep 'pointStats' num2str(iStack,'%3.5d')];
    % does not overwrite if both files are present
    if ~exist(fileName2,'file') && ~exist(fileName3,'file')
        tic
        WormCLStraighten_11(dataFolder,destination,vidInfo,...
            alignments,Vtemplate,zOffset,iStack,side,0); 
        display(['image' num2str(iStack,'%3.5d') 'completed in ' num2str(toc) 's']);
    else
        display([ 'image' num2str(iStack,'%3.5d') '.tif already exist!'])
    end
end
