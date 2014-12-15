function [metadata,imageInfo]=getHamMetadata(imageName)
%takes tiff file from hammamatsu camera and outputs structure with fields
%and string outputs. 

imageInfo=imfinfo(imageName);
dataString=imageInfo.ImageDescription;
dataString=strrep(dataString, ' ' ,'');
dataLines= textscan(dataString,'%s');
dataLines=dataLines{1};
fieldLines=cellfun(@(x) strfind(x,'='),dataLines,'uniformoutput',false);

equalSigns=cellfun(@(x) ~isempty(x),fieldLines,'uniformoutput',false);
metadata=[];

dataLines=dataLines(cell2mat(equalSigns));
fieldLines=fieldLines(cell2mat(equalSigns));
fieldLines=cellfun(@(x) x(1), fieldLines);

fieldNames=cellfun(@(i) dataLines{i}(1:fieldLines(i)-1),...
    num2cell(1:length(dataLines)),'uniformoutput',0);

fieldValues=cellfun(@(i) dataLines{i}(fieldLines(i)+1:end),...
    num2cell(1:length(dataLines)),'uniformoutput',0);



metadata=cell2struct(fieldValues,fieldNames,2);


% for iField=1:length(equalSigns)
%     if equalSigns{iField}
%         dataline=dataLines{iField};
%         equalSpot=fieldLines{iField};
%         equalSpot=equalSpot(1);
%         
%     metadata=setfield(metadata,dataline(1:equalSpot-1),dataline(equalSpot+1 ...
%     :end));
% 
%     
%     end
% end
