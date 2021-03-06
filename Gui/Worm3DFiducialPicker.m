function varargout = Worm3DFiducialPicker(varargin)
% WORM3DFIDUCIALPICKER MATLAB code for Worm3DFiducialPicker.fig
%      WORM3DFIDUCIALPICKER, by itself, creates a new WORM3DFIDUCIALPICKER or raises the existing
%      singleton*.
%
%      H = WORM3DFIDUCIALPICKER returns the handle to a new WORM3DFIDUCIALPICKER or the handle to
%      the existing singleton*.
%
%      WORM3DFIDUCIALPICKER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WORM3DFIDUCIALPICKER.M with the given input arguments.
%
%      WORM3DFIDUCIALPICKER('Property','Value',...) creates a new WORM3DFIDUCIALPICKER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Worm3DFiducialPicker_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Worm3DFiducialPicker_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Worm3DFiducialPicker

% Last Modified by GUIDE v2.5 21-Dec-2014 20:11:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Worm3DFiducialPicker_OpeningFcn, ...
    'gui_OutputFcn',  @Worm3DFiducialPicker_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Worm3DFiducialPicker is made visible.
function Worm3DFiducialPicker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Worm3DFiducialPicker (see VARARGIN)

% Choose default command line output for Worm3DFiducialPicker

%set up slider
handles.output = hObject;
hlistener=addlistener(handles.slider1,'ContinuousValueChange',...
    @plotter);
hlistenerz=addlistener(handles.zSlider,'ContinuousValueChange',...
    @plotter);
setappdata(handles.zSlider,'hlistener',hlistenerz);
set(handles.zSlider,'SliderStep',[1,1]);

setappdata(handles.slider1,'hlistener',hlistener);
set(handles.slider1,'SliderStep',[1,1]);
setappdata(handles.figure1,'points',0)
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Worm3DFiducialPicker wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Worm3DFiducialPicker_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in SelectFolder.
function SelectFolder_Callback(hObject, eventdata, handles)
% hObject    handle to SelectFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%select folers with data,


%select image folder
display('Select image folder,');
mostRecent=getappdata(0,'mostRecent');
if isempty(mostRecent)
imFiles=uipickfiles();
else
    imFiles=uipickfiles('filterspec', mostRecent);
end
    mostRecent=imFiles{1};
    if ~isdir(mostRecent)
        mostRecent=fileparts(mostRecent);
    end
    setappdata(0,'mostRecent',mostRecent);

%load registration file if needed for split
[rpath,parent]=uigetfile('Y:\CommunalCode\3dbrain\registration','Select Registration File');
registration=load([parent filesep rpath]);
setappdata(0,'registration',registration);

if exist([imFiles{1} filesep 'hiResData.mat'],'file')
    hiResData=load([imFiles{1} filesep 'hiResData']);
    hiResData=hiResData.dataAll;
else
    %only for 1200 by 600 image for now
    hiResData=highResTimeTraceAnalysisTriangle4(imFiles{1},1200,600);
end
setappdata(handles.figure1,'hiResData',hiResData');
setappdata(handles.figure1,'imFiles',imFiles);
%setting slider parameters
set(handles.slider1,'Min',1)
set(handles.slider1,'Value',1)
setappdata(handles.figure1,'cursorTarget', 1);

maxFrame=max(hiResData.stackIdx);
minZ=min(hiResData.Z);
maxZ=max(hiResData.Z);
minFrame=1;
set(handles.maxTime,'String',num2str(maxFrame));
set(handles.minTime,'String',num2str(minFrame));
set(handles.slider1,'max',maxFrame);
setappdata(handles.figure1,'currentFrame',1);
set(handles.slider1,'value',1);
set(handles.zSlider,'min',minZ);
set(handles.zSlider,'max', maxZ);
set(handles.zSlider,'value',(maxZ+minZ)/2);
fiducialPoints=cell(50,1);
fiducialPoints=repmat({fiducialPoints},max(hiResData.stackIdx),1);
setappdata(handles.figure1,'fiducials',fiducialPoints);
set(handles.currentFiducialFile,'String',...
    [mostRecent filesep datestr(now,'yyyymmddTHHMMSS') 'Fiducials']);

plotter(handles.slider1,eventdata);



% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%plotter(handles.slider1,eventdata);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
%setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function plotter(hObject,eventdata)

%plots current frame in image window and plot window

handles=guidata(get(hObject,'Parent'));
iImage=round(get(handles.slider1,'Value'));
zPos=(get(handles.zSlider,'Value'));
zPos=zPos(1);
if isempty(zPos)
    zPos=1;
    set(handles.zSlider,'Value',1);
end

% minFrame=str2double(get(handles.minTime,'string'));
% maxFrame=str2double(get(handles.maxTime,'string'));
offset=str2double(get(handles.timeOffset,'string'));

imFiles=getappdata(handles.figure1,'imFiles');
    %for selection of dat files
    
    hiResData=getappdata(handles.figure1,'hiResData');
    R=getappdata(0,'registration');
    [row,col]=size(R.initialIm);
    imFiles=imFiles{1};
     FrameIdx=getappdata(handles.figure1,'FrameIdx');
    zVoltages=getappdata(handles.figure1,'zVoltages'); 
    
if iImage~=getappdata(handles.figure1,'currentFrame') | isempty(zVoltages)
    
FrameIdx=find(hiResData.stackIdx==iImage);%+offset;
FrameIdx=FrameIdx(FrameIdx>(-offset) & FrameIdx<length(hiResData.stackIdx));
zVoltages=hiResData.Z(FrameIdx);
[zVoltages,~,ia]=unique(zVoltages);
FrameIdx=FrameIdx(ia);
[~,ib]=sort(zVoltages,'ascend');
zVoltages=zVoltages(ib);
FrameIdx=FrameIdx(ib);
setappdata(handles.figure1,'FrameIdx',FrameIdx);
setappdata(handles.figure1,'zVoltages',zVoltages);
 
    
end


stdPlot=hiResData.imSTD(FrameIdx+offset);
stdPlot=smooth(stdPlot,5);
[~,stdPeak]=max(stdPlot);
%zVoltages=zVoltages-zVoltages(stdPeak)+.2;
zSlice=interp1(zVoltages,1:length(zVoltages),zPos,'nearest','extrap');
zVoltageOut=zVoltages(zSlice);
set(handles.zSlider,'Value',zVoltageOut);
%    hiResIdx=metaData.iFrame(zSlice);
hiResIdx=FrameIdx(zSlice)+offset;
setappdata(handles.figure1,'currentHiResIdx',hiResIdx);
Fid=getappdata(handles.figure1,'fileID');
if isempty(Fid)
Fid=fopen([imFiles filesep 'sCMOS_Frames_U16_1024x1024.dat'] );
setappdata(handles.figure1,'fileID',Fid);
elseif Fid<=0;
    Fid=fopen([imFiles filesep 'sCMOS_Frames_U16_1024x1024.dat'] );
setappdata(handles.figure1,'fileID',Fid);
end
    
    status=fseek(Fid,2*hiResIdx*row*col,-1);
    temp=fread(Fid,row*col,'uint16',0,'l');
    temp=(reshape(temp,row,col));
   % fclose(Fid)
    %     temp=pixelIntensityCorrection(temp);
    %crop left and right regions
    rect1=R.rect1;
    rect2=R.rect2;
    t_concord=R.t_concord;
    Rsegment=R.Rsegment;
    padRegion=R.padRegion;
    worm=temp((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3));
    
    if get(handles.channelSelect,'Value')==1
    baseImg=worm; %red   
    else 
        activity=temp((rect2(2)+1):rect2(4),(1+rect2(1)):rect2(3));
        baseImg=imwarp(activity,t_concord,'OutputView',Rsegment);
    end
    
setappdata(handles.figure1,'baseImg',baseImg);
setappdata(handles.figure1,'hiResIdx',hiResIdx);
    
   % baseImg=pedistalSubtract(baseImg);
setappdata(handles.figure1,'currentFrame',iImage);
setappdata(0,'baseImg',baseImg)
%     figure
%     imagesc(smooth2a(baseImg,20,20)>5);
timeStep=str2double(get(handles.timeStep,'String'));
   set(handles.FrameIdx,'string',[num2str(iImage*timeStep,'%6.2f') 's' ...
         '  ' num2str(zVoltageOut)]);
 %    set(handles.FrameIdx,'string',stackName);

        newContrast=getappdata(handles.figure1,'newContrast');
        if isempty(newContrast)
            newContrast=[min(baseImg(:)),max(baseImg(:))];
        end
%         baseImg(baseImg<newContrast(1)) = newContrast(1);
%         baseImg(baseImg>newContrast(2)) = newContrast(2);
%         baseImg = (baseImg-newContrast(1))./diff(newContrast);
        hold(handles.axes1,'off')

    ax1=imagesc(baseImg,'parent',handles.axes1);
    set(ax1,'ButtonDownFcn',...
'Worm3DFiducialPicker(''axes1_ButtonDownFcn'',gcbo,[],guidata(gcbo))')
caxis(handles.axes1, [newContrast]);
    hold(handles.axes1,'on')
    axis(handles.axes1,'equal');
    
    
%  B=bwboundaries(wormMask(:,:,zSlice));
%   
%     for i=1:length(B)
%         b=B{i};
%         plot(handles.axes1,b(:,2),b(:,1),'b')
%     end
    plotCircle(handles)
    plot(handles.axes4,stdPlot,zVoltages);
    ylim(handles.axes4,[get(handles.zSlider,'Min'),get(handles.zSlider,'Max')]);

    fiducialPoints=getappdata(handles.figure1,'fiducials');
    currentFiducials=fiducialPoints{iImage};
    set(handles.DisplayIdx,'data',currentFiducials);
    plotIdx=find(cell2mat((cellfun(@(x) ~isempty(x),currentFiducials(:,1),'uniformoutput',0))));
currentPoints=cell2mat(currentFiducials);
circleScatter=getappdata(handles.figure1,'circleScatter');
if ishandle(circleScatter); delete(circleScatter);end
circleLabel=getappdata(handles.figure1,'circleLabel');
if ishandle(circleLabel); delete(circleLabel);end


if ~isempty(currentPoints)
hold(handles.axes2,'on')
randPos=(mod(plotIdx.^(1.4),5)-2)/2;
circleScatter=scatter(handles.axes2,randPos,currentPoints(:,3),'xr');


setappdata(handles.figure1,'circleScatter',circleScatter);
hold(handles.axes2,'off');


%inSlice=interp1(zVoltages,1:length(zVoltages),currentPoints(:,4),'nearest','extrap');
closeSlice=abs(currentPoints(:,4)-hiResIdx)<2;
perfectSlice=currentPoints(:,4)==hiResIdx;
if getappdata(handles.figure1,'show')
scatter(handles.axes1,currentPoints(closeSlice,1),currentPoints(closeSlice,2),'black');
scatter(handles.axes1,currentPoints(perfectSlice,1),currentPoints(perfectSlice,2),'xr');

    text( currentPoints(closeSlice,1), currentPoints(closeSlice,2),cellstr(num2str(plotIdx(closeSlice))),'VerticalAlignment'...
        ,'bottom', 'HorizontalAlignment','right','color',[1 1 1],...
        'fontsize',10,'parent',handles.axes1);
end
    
    circleLabel=text( randPos, currentPoints(:,3),cellstr(num2str(plotIdx)),'VerticalAlignment'...
        ,'bottom', 'HorizontalAlignment','right','color',[0 0 0],...
        'fontsize',10,'parent',handles.axes2);
    setappdata(handles.figure1,'circleLabel',circleLabel);

end
    hold(handles.axes1,'off')

   %     scat3=scatter3(handles.axes1,centroids(:,2),centroids(:,1),centroids(:,3),[],c);
        

        
    %display circle on axis 2
function plotCircle(handles)
ylim(handles.axes2,[get(handles.zSlider,'Min'),get(handles.zSlider,'Max')]);

h=getappdata(handles.figure1,'circHandle');
if isempty(h)
    cla(handles.axes2)
center=[0,.5];
radius=1;
h=viscircles(handles.axes2, center,radius);
setappdata(handles.figure1,'circHandle',h);
ylim(handles.axes2,[get(handles.zSlider,'Min'),get(handles.zSlider,'Max')]);
end


g=getappdata(handles.figure1,'lineHandle');
if isempty(g)
    
hold(handles.axes2,'on')
g=plot(handles.axes2,[-1,1], repmat(get(handles.zSlider,'Value'),1,2));
hold(handles.axes2,'off');
setappdata(handles.figure1,'lineHandle',g);
else
    if ishandle(g)
    set(g,'Ydata', repmat(get(handles.zSlider,'Value'),1,2));
    else
hold(handles.axes2,'on')
g=plot(handles.axes2,[-1,1], repmat(get(handles.zSlider,'Value'),1,2));
hold(handles.axes2,'off');
setappdata(handles.figure1,'lineHandle',g);
    end
    
end


% --- Executes on selection change in cmapping.
function cmapping_Callback(hObject, eventdata, handles)
% hObject    handle to cmapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String'));
Cstyle=contents{get(hObject,'Value')};
colormap(handles.axes1,Cstyle);

% Hints: contents = cellstr(get(hObject,'String')) returns cmapping contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmapping


% --- Executes during object creation, after setting all properties.
function cmapping_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cmapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in goBack.
function goBack_Callback(hObject, eventdata, handles)
% hObject    handle to goBack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FPS=1;%getappdata(handles.figure1,'FPS');
set(handles.slider1,'value',get(handles.slider1,'value')-FPS);
currentSlide=get(handles.zSlider,'value');
currentFrame=round(get(handles.slider1,'value'));
if 1
        fiducialPoints=getappdata(handles.figure1,'fiducials');
        currentFiducials=fiducialPoints{currentFrame};
        currentTarget=getappdata(handles.figure1,'cursorTarget');
       currentPlotIdx=find(cell2mat((cellfun(@(x) ~isempty(x),currentFiducials(:,1),'uniformoutput',0))));

if size(currentFiducials,1)>=currentTarget && size(currentFiducials,2)>1
    newZ=currentFiducials{currentTarget,3};
else
    newZ=[];
end

if isempty(newZ)
    try
        oldFiducialPoints=fiducialPoints{currentFrame+1};
            oldPlotIdx=find(cell2mat((cellfun(@(x) ~isempty(x),oldFiducialPoints(:,1),'uniformoutput',0))));
overlap=intersect(currentPlotIdx,oldPlotIdx);
        oldzVoltages=sort([oldFiducialPoints{overlap,3}])+(1:length(overlap))/100;
        currentzVoltages=sort([currentFiducials{overlap,3}])+(1:length(overlap))/100;
newZ=interp1(oldzVoltages,currentzVoltages,currentSlide,'linear',1);


    catch
        newZ=currentSlide;
    end
    
end
    
set(handles.zSlider,'value',min(newZ,get(handles.zSlider,'max')));
    
end

plotter(handles.slider1,eventdata)
if get(handles.Continuous,'Value')
    cursorNeuronSelect(handles.slider1,eventdata)
end



% --- Executes on button press in goForward.
function goForward_Callback(hObject, eventdata, handles)
% hObject    handle to goForward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%FPS=getappdata(handles.figure1,'FPS');
FPS=1;

set(handles.slider1,'value',get(handles.slider1,'value')+FPS);
currentSlide=get(handles.zSlider,'value');
currentFrame=round(get(handles.slider1,'value'));
%setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));
        fiducialPoints=getappdata(handles.figure1,'fiducials');

if ~isempty(fiducialPoints)
        currentFiducials=fiducialPoints{currentFrame};
        currentTarget=getappdata(handles.figure1,'cursorTarget');
       currentPlotIdx=find(cell2mat((cellfun(@(x) ~isempty(x),currentFiducials(:,1),'uniformoutput',0))));
oldFiducials=fiducialPoints{max(currentFrame-2,1)};
if size(currentFiducials,1)>=currentTarget && size(currentFiducials,2)>1 && ~strcmp(eventdata.Key, 'e')

    newZ=currentFiducials{currentTarget,3};
else
    newZ=[];
end
if isnan(newZ)
    newZ=[];
end
        oldFiducialPoints=fiducialPoints{currentFrame-1};

if isempty(newZ)
    try
    if ~isempty(oldFiducialPoints{currentTarget,3})
            oldPlotIdx=find(cell2mat((cellfun(@(x) ~isempty(x),oldFiducialPoints(:,1),'uniformoutput',0))));
overlap=intersect(currentPlotIdx,oldPlotIdx);

        oldzVoltages=([oldFiducialPoints{overlap,3}])+(1:length(overlap))/100;
        currentzVoltages=([currentFiducials{overlap,3}])+(1:length(overlap))/100;
        nans=any(isnan([oldzVoltages currentzVoltages]),1);
        oldzVoltages=oldzVoltages(~nans(overlap));
        currentzVoltages=currentzVoltages(~nans(overlap));
        if isempty(oldFiducialPoints(currentTarget,1))
              f=polyfit(oldzVoltages,currentzVoltages,1);
newZ=f(2)+f(1)*(oldFiducialPoints{currentTarget,3});
  %  newZ=interp1(oldzVoltages,currentzVoltages,currentSlide,'linear','extrap');

else
    oldFiducialPoints(currentTarget,3);
    f=polyfit(oldzVoltages,currentzVoltages,1);
newZ=f(2)+f(1)*(oldFiducialPoints{currentTarget,3});
     %   newZ=interp1(oldzVoltages,currentzVoltages,oldFiducialPoints{currentTarget,3},'linear','extrap');

end


    else
        newZ=currentSlide;
    end
    catch
        newZ=currentSlide;
    end
    
    
end
    
set(handles.zSlider,'value',min(newZ,get(handles.zSlider,'max')));
    
end

plotter(handles.slider1,eventdata)
if get(handles.Continuous,'Value')
    cursorNeuronSelect(handles.slider1,eventdata)
end




% --- Executes on selection change in plotChannel.
function plotChannel_Callback(hObject, eventdata, handles)
% hObject    handle to plotChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotter(handles.slider1,'eventdata');
% Hints: contents = cellstr(get(hObject,'String')) returns plotChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plotChannel


% --- Executes during object creation, after setting all properties.
function plotChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectNeuron1.
function selectNeuron1_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',1);
%cursorNeuronSelect(hObject,eventdata)
%displayIdx=get(handles.DisplayIdx,'data');

% --- Executes on button press in selectNeuron2.
function selectNeuron2_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',2);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron3.
function selectNeuron3_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',3);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron4.
function selectNeuron4_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',4);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron5.
function selectNeuron5_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',5);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron6.
function selectNeuron6_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',6);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron7.
function selectNeuron7_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',7);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron8.
function selectNeuron8_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',8);
%cursorNeuronSelect(hObject,eventdata)


% --- Executes on button press in selectNeuron9.
function selectNeuron9_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',9);
%cursorNeuronSelect(hObject,eventdata)


% --- Executes on button press in selectNeuron10.
function selectNeuron10_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',10);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron11.
function selectNeuron11_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',11);
%cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron12.
function selectNeuron12_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',12);
%cursorNeuronSelect(hObject,eventdata)
% --- Executes on button press in selectNeuronN.
function selectNeuronN_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuronN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
N=str2double(get(handles.N,'String'));
setappdata(handles.figure1,'cursorTarget',N);

%cursorNeuronSelect(hObject,eventdata)


% --- Executes on button press in selectNeuronM.
function selectNeuronM_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuronM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=str2double(get(handles.M,'String'));
setappdata(handles.figure1,'cursorTarget',M);


function cursorNeuronSelect(hObject,eventdata)

handles=guidata(get(hObject,'Parent'));


[xselect,yselect]=ginput(1);
windowSearch=str2double(get(handles.xySearch,'String'));
zSearch=str2double(get(handles.zSearch,'String'));
cornersX=xselect+[windowSearch windowSearch -windowSearch -windowSearch windowSearch];
cornersY=yselect+[windowSearch -windowSearch -windowSearch windowSearch windowSearch];


inputData(hObject,xselect,yselect,windowSearch,zSearch)
setappdata(handles.figure1,'lastClick',[xselect yselect]);
hold(handles.axes1,'on')
plot(handles.axes1,cornersX,cornersY,'g')
hold(handles.axes1,'off');

function exactNeuronSelect(hObject,eventdata)

handles=guidata(get(hObject,'Parent'));
[xselect,yselect]=ginput(1);
windowSearch=1;
zSearch=0;
cornersX=xselect+[windowSearch windowSearch -windowSearch -windowSearch windowSearch];
cornersY=yselect+[windowSearch -windowSearch -windowSearch windowSearch windowSearch];


inputData(hObject,xselect,yselect,windowSearch,zSearch)
setappdata(handles.figure1,'lastClick',[xselect yselect]);
hold(handles.axes1,'on')
plot(handles.axes1,cornersX,cornersY,'g')
hold(handles.axes1,'off');



function autoSelect(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));
iFrame=getappdata(handles.figure1,'currentFrame');
fiducialPoints=getappdata(handles.figure1,'fiducials');
currentFiducials=fiducialPoints{iFrame};

oldFrameIdx=str2double(get(handles.refIdx,'String'));
if isnan(oldFrameIdx)
    oldFrameIdx=iFrame-1;
elseif oldFrameIdx<0
    oldFrameIdx=iFrame+(-1:-1:oldFrameIdx);
end
%search for previous data with similar distance matrix
plotIdx=getappdata(handles.figure1,'cursorTarget');
currentFiducialIdx=find(cell2mat((cellfun(@(x) ~isempty(x),currentFiducials(:,1),'uniformoutput',0))));
currentFiducialIdx=currentFiducialIdx(~isnan(cell2mat(currentFiducials(currentFiducialIdx,1))));

maxOverlap=0; bestDistance=Inf;
for iRefFrame=oldFrameIdx
oldFiducials=fiducialPoints{iRefFrame};
oldFiducialIdx=find(cell2mat((cellfun(@(x) ~isempty(x),oldFiducials(:,1),'uniformoutput',0))));
oldFiducialIdx=oldFiducialIdx(~isnan(cell2mat(oldFiducials(oldFiducialIdx,1))));
overlapIdx=intersect(oldFiducialIdx,currentFiducialIdx);
if ~isempty(overlapIdx) && any(oldFiducialIdx==plotIdx)
    overlapIdx(overlapIdx==plotIdx)=[];
movingPointstemp=cell2mat(oldFiducials(overlapIdx,[1:2 4]));
masterPointstemp=cell2mat(currentFiducials(overlapIdx,[1:2 4]));
if length(overlapIdx)>=maxOverlap
    movingDmat=pdist(movingPointstemp(:,1:2));
    masterDmat=pdist(masterPointstemp(:,1:2));
    
    tempDistance=sum((movingDmat-masterDmat).^2);
    if length(overlapIdx)>maxOverlap || tempDistance<bestDistance
    bestDistance=tempDistance;
    movingPoints=movingPointstemp;
    masterPoints=masterPointstemp;
 plotIdxPoint=cell2mat(oldFiducials(plotIdx,[1:2 4]));
    end
    maxOverlap=length(overlapIdx);
end

end
end

movingFloor=min(movingPoints(:,3))-5;
masterFloor=min(masterPoints(:,3))-5;
movingPoints(:,end)=movingPoints(:,end)-movingFloor;
masterPoints(:,end)=masterPoints(:,end)-masterFloor;
plotIdxPoint(:,end)=plotIdxPoint(:,end)-movingFloor;
%tform = makeAffine3d(movingPoints, masterPoints);
% [newEstimatePoint(:,1),newEstimatePoint(:,2),newEstimatePoint(:,3)]...
%     =transformPointsInverse(tform,plotIdxPoint(:,1),...
%     plotIdxPoint(:,2),plotIdxPoint(:,3));
% Fx=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),movingPoints(:,3),masterPoints(:,1));
% Fy=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),movingPoints(:,3),masterPoints(:,2));
%Fz=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),movingPoints(:,3),masterPoints(:,3));

Fx=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),masterPoints(:,1));
Fy=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),masterPoints(:,2));
%Fz=scatteredInterpolant(movingPoints(:,1),movingPoints(:,2),movingPoints(:,3),masterPoints(:,3));

newEstimatePoint=[Fx(plotIdxPoint(1),plotIdxPoint(2))...
    Fy(plotIdxPoint(1),plotIdxPoint(2))];

% newEstimatePoint(1)=Fx(plotIdxPoint(1),plotIdxPoint(2),plotIdxPoint(3));
%newEstimatePoint(2)=Fy(plotIdxPoint(1),plotIdxPoint(2),plotIdxPoint(3));
%newEstimatePoint(3)=Fz(plotIdxPoint(1),plotIdxPoint(2),plotIdxPoint(3));

windowSearch=str2double(get(handles.xySearch,'String'));
zSearch=str2double(get(handles.zSearch,'String'));

cornersX=newEstimatePoint(:,1)+[windowSearch windowSearch -windowSearch -windowSearch windowSearch];
cornersY=newEstimatePoint(:,2)+[windowSearch -windowSearch -windowSearch windowSearch windowSearch];

inputData(hObject,newEstimatePoint(:,1),newEstimatePoint(:,2),windowSearch,zSearch)
setappdata(handles.figure1,'lastClick',[newEstimatePoint(:,1:2)]);
hold(handles.axes1,'on')
plot(handles.axes1,cornersX,cornersY,'g')
hold(handles.axes1,'off');




%            [affineFiducials(:,1),affineFiducials(:,2),affineFiducials(:,3)]...
%                =transformPointsForward(tform,movingPoints(:,1),...
%                movingPoints(:,2),movingPoints(:,3));   
%            
% 
% newEstimatePoint=tpswarp3(affineFiducials,[],masterPoints,affineFiducials);
function reclick(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));

newEstimatePoint=getappdata(handles.figure1,'lastClick');
windowSearch=str2double(get(handles.xySearch,'String'));
zSearch=str2double(get(handles.zSearch,'String'));
cornersX=newEstimatePoint(:,1)+[windowSearch windowSearch -windowSearch -windowSearch windowSearch];
cornersY=newEstimatePoint(:,2)+[windowSearch -windowSearch -windowSearch windowSearch windowSearch];
inputData(hObject,newEstimatePoint(:,1),newEstimatePoint(:,2),windowSearch,zSearch)
setappdata(handles.figure1,'lastClick',[newEstimatePoint(:,1:2)]);
hold(handles.axes1,'on')
plot(handles.axes1,cornersX,cornersY,'g')
hold(handles.axes1,'off');


function inputData(hObject,xselect,yselect,windowSearch,zSearch)
handles=guidata(get(hObject,'Parent'));
iFrame=getappdata(handles.figure1,'currentFrame');
fiducialPoints=getappdata(handles.figure1,'fiducials');
currentFiducials=fiducialPoints{iFrame};
zPos=get(handles.zSlider,'Value');
zPos=zPos(1);
timeOffset=str2double(get(handles.timeOffset,'String'));
xRange=xlim(handles.axes1);
yRange=ylim(handles.axes1);
plotIdx=getappdata(handles.figure1,'cursorTarget');
% if you click outside the image, the centroid will become nan
if xselect>xRange(1) && xselect< xRange(2) && yselect>yRange(1) && yselect<yRange(2);
 % turn on snapping later
%     minD=pdist2([xselect,yselect],currentCentroids(:,1:2),'euclidean','smallest',1);
%     pointIdx=find(minD==min(minD),1,'first');
%     pointIdx=currentCentroids(pointIdx,3);
%     
%baseImg=getappdata(0,'baseImg');
filterSize=str2double(get(handles.filterSize,'String'));
if ~isempty(filterSize)
    switch get(handles.filterOption,'Value')
        case 1
            if filterSize>0
gaussFilter=fspecial('gaussian', [10,10],filterSize);
            else 
                gaussFilter=1;
            end
            
        case 2
gaussFilter=-fspecial('log', [10,10],filterSize);

    end
    
else
    gaussFilter=fspecial('gaussian', [10,10],4);
    set(handles.filterSize,'String','4')
end
%baseImg=imfilter(baseImg,gaussFilter);
%subSearch=baseImg(round(yselect)+(-windowSearch:windowSearch),round(xselect)+(-windowSearch:windowSearch));
%look in small volume around point
Fid=getappdata(handles.figure1,'fileID');
hiResIdx=getappdata(handles.figure1,'currentHiResIdx');
frameIdx=getappdata(handles.figure1,'FrameIdx');

if isempty(Fid)
Fid=fopen([imFiles filesep 'sCMOS_Frames_U16_1024x1024.dat'] );
setappdata(handles.figure1,'fileID',Fid);
end
        R=getappdata(0,'registration');
    [row,col]=size(R.initialIm);
    status=fseek(Fid,2*(hiResIdx-zSearch)*row*col,-1);
    temp=fread(Fid,row*col*(2*zSearch+1),'uint16',0,'l');
    temp=(reshape(temp,row,col,(2*zSearch+1)));
   % fclose(Fid)
    %     temp=pixelIntensityCorrection(temp);
    %crop left and right regions
    rect1=R.rect1;
    rect2=R.rect2;
    t_concord=R.t_concord;
    Rsegment=R.Rsegment;
    padRegion=R.padRegion;
    
        
    if get(handles.channelSelect,'Value')==1
    worm=temp((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),:);
    else 
        worm=temp((rect2(2)+1):rect2(4),(1+rect2(1)):rect2(3),:);
        worm=imwarp(worm,t_concord,'OutputView',Rsegment);

    end
    
    worm=imfilter(worm,gaussFilter);
    subSearch=worm(round(yselect)+(-windowSearch:windowSearch),round(xselect)+(-windowSearch:windowSearch),:);
maxRegions=imregionalmax(subSearch);
if ~any(maxRegions)
    maxRegions=(subSearch==max(subSearch));
end

[maxPosY,maxPosX,maxPosZ]=ind2sub(size(subSearch),find(maxRegions));


zVoltages=getappdata(handles.figure1,'zVoltages');
if mean(diff(frameIdx))>0
subZVoltages=zVoltages(interp1(sort(frameIdx)+(1:length(frameIdx))'/100,...
    1:length(frameIdx),hiResIdx-timeOffset+(-zSearch:zSearch),'nearest',1));
else
    subZVoltages=zVoltages(interp1(sort(frameIdx,'descend')+(length(frameIdx):-1:1)'/100,...
        1:length(frameIdx),hiResIdx-timeOffset+(-zSearch:zSearch),'nearest',1));

end
maxVals=subSearch(maxRegions);
xselect=xselect-windowSearch+maxPosX-1;
yselect=yselect-windowSearch+maxPosY-1;
zselect=subZVoltages(maxPosZ);

if length(xselect)>1
 if size(currentFiducials,2)<3
    currentXY=[0 0 0];
else
    currentXY=cell2mat(currentFiducials(:,1:3));
 end
    
    %get only points that are further than 10 from all current points in the plane
dmat=pdist2([xselect,yselect], currentXY(:,1:2))<10;
eqmat=bsxfun(@minus ,zselect,currentXY(:,3)');
eqmat=abs(eqmat)<=.15;
goodPoints=find(~any(dmat & eqmat,2)); 
if isempty(goodPoints)
    goodPoints=1:length(maxVals);
end

goodPoints=goodPoints((maxVals(goodPoints)==max(maxVals(goodPoints))));

xselect=xselect(goodPoints);
yselect=yselect(goodPoints);
zselect=zselect(goodPoints);
maxPosZ=maxPosZ(goodPoints);
end
set(handles.zSlider,'Value',zselect)

    ctrlPnt=[xselect,yselect,zselect];
    currentFiducials{plotIdx,4}=getappdata(handles.figure1,'currentHiResIdx')-(zSearch+1)+maxPosZ(1);
currentFiducials{plotIdx,1}=ctrlPnt(1);
currentFiducials{plotIdx,2}=ctrlPnt(2);
currentFiducials{plotIdx,3}=ctrlPnt(3);
else
    currentFiducials{plotIdx,1}=[];
currentFiducials{plotIdx,2}=[];
currentFiducials{plotIdx,3}=[];
        currentFiducials{plotIdx,4}=[];

end

% if ~size(plotIdx
% end



fiducialPoints{iFrame}=currentFiducials;
set(handles.DisplayIdx,'data',currentFiducials);

setappdata(handles.figure1,'fiducials',fiducialPoints);
if get(handles.savingFiducials,'Value')
    timeOffset=str2double(get(handles.timeOffset,'String'));
    
    save(get(handles.currentFiducialFile,'String'), 'timeOffset','fiducialPoints')
end


pointUpdate(handles)
plotter(handles.slider1,'eventdata');


% --- Executes on button press in clearPlots.
function clearPlots_Callback(hObject, eventdata, handles)
% hObject    handle to clearPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.DisplayIdx,'data', {[];[];[];[];[];[];[];[]});
cla(handles.axes2);



% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in goUp.
function goUp_Callback(hObject, eventdata, handles)
% hObject    handle to goUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)set(handles.slider1,'value',get(handles.slider1,'value')+1);
zVoltages=getappdata(handles.figure1,'zVoltages');
currentZ=get(handles.zSlider,'value');
currentZ=currentZ(1);
if currentZ<max(zVoltages)
newZ=zVoltages((find(zVoltages>currentZ,1,'first')));
else newZ=currentZ;
end
set(handles.zSlider,'value',min(newZ,get(handles.zSlider,'max')));
plotter(hObject,eventdata)

% --- Executes on button press in goDown.
function goDown_Callback(hObject, eventdata, handles)
% hObject    handle to goDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zVoltages=getappdata(handles.figure1,'zVoltages');
currentZ=get(handles.zSlider,'value');
if currentZ>min(zVoltages)
newZ=zVoltages((find(zVoltages<currentZ,1,'last')));
else newZ=currentZ;
end
set(handles.zSlider,'value',min(newZ,get(handles.zSlider,'max')));
plotter(hObject,eventdata)




function timeStep_Callback(hObject, eventdata, handles)
% hObject    handle to timeStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeStep as text
%        str2double(get(hObject,'String')) returns contents of timeStep as a double
timeStep=str2double(get(handles.timeStep,'string'));
maxFrame=str2double(get(handles.maxTime,'String'))/timeStep;
set(handles.maxTime,'String',num2str(maxFrame));
minFrame=str2double(get(handles.minTime,'String'))/timeStep;
set(handles.minTime,'String',num2str(minFrame));


% --- Executes during object creation, after setting all properties.
function timeStep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function adjustContrast_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to adjustContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% display the base image, calculate the display image;
baseImg = getappdata(handles.figure1,'baseImg');
imageHandle = findobj('Parent',handles.axes1,'type','image');
storedImage = get(imageHandle);
set(imageHandle,'cdata',baseImg,'cdataMapping','scaled');


% imshow(baseImg,[]);
contrastWindow = imcontrast(handles.axes1);
waitfor(contrastWindow);
newContrast = getDisplayRange(getimagemodel(findobj('parent',handles.axes1,'type','image')));
baseImg(baseImg<newContrast(1)) = newContrast(1);
baseImg(baseImg>newContrast(2)) = newContrast(2);
baseImg = (baseImg-newContrast(1))./diff(newContrast);
setappdata(handles.figure1,'displayImg',baseImg);
setappdata(handles.figure1,'newContrast',newContrast);

% currentColorMask = double(repmat(baseImg,[1,1,3]));
% currentColorMask = currentColorMask*0.8+coloredLabels.*0.2.*(1/255);
% set(imageHandle,'cdataMapping','direct');
% set(imageHandle,'cdata',currentColorMask);

% --- Executes on button press in alignmentSelect.
function alignmentSelect_Callback(hObject, eventdata, handles)
% hObject    handle to alignmentSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[rpath,parent]=uigetfile('Y:\CommunalCode\3dbrain\');
registration=load([parent filesep rpath]);
setappdata(0,'registration',registration);


% --- Executes on slider movement.
function zSlider_Callback(hObject, eventdata, handles)
% hObject    handle to zSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function zSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in centerlineSelect.



function maxTime_Callback(hObject, eventdata, handles)
% hObject    handle to maxTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxTime as text
%        str2double(get(hObject,'String')) returns contents of maxTime as a double
timeStep=str2double(get(handles.timeStep,'string'));
maxFrame=str2double(get(hObject,'String'))/timeStep;

set(handles.slider1,'Max', maxFrame)

% --- Executes during object creation, after setting all properties.
function maxTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minTime_Callback(hObject, eventdata, handles)
% hObject    handle to minTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minTime as text
%        str2double(get(hObject,'String')) returns contents of minTime as a double

timeStep=str2double(get(handles.timeStep,'string'));

minFrame=str2double(get(hObject,'String'))/timeStep;
set(handles.slider1,'Min',minFrame )
set(handles.slider1,'Value',minFrame);


% --- Executes during object creation, after setting all properties.
function minTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timeOffset_Callback(hObject, eventdata, handles)
% hObject    handle to timeOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeOffset as text
%        str2double(get(hObject,'String')) returns contents of timeOffset as a double


% --- Executes during object creation, after setting all properties.
function timeOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
 


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, evnt, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
     
        %Forward
        if strcmp(evnt.Key,'rightarrow')|| strcmp(evnt.Key,'d')
            goForward_Callback(handles.slider1,evnt,handles);
            
        %Backward
        elseif strcmp(evnt.Key,'backspace') || strcmp(evnt.Key,'leftarrow')|| strcmp(evnt.Key,'a')
            goBack_Callback(handles.slider1,evnt,handles);
        %Up
        elseif  strcmp(evnt.Key,'uparrow')|| strcmp(evnt.Key,'w')
            goUp_Callback(handles.zSlider,evnt,handles);
        %Down
        elseif strcmp(evnt.Key,'downarrow')|| strcmp(evnt.Key,'s')
            goDown_Callback(handles.zSlider,evnt,handles);
        elseif strcmp(evnt.Key,'space')
            cursorNeuronSelect(handles.slider1,evnt)
        elseif strcmp(evnt.Key,'e');
            goForward_Callback(handles.slider1,evnt,handles);
            autoSelect(handles.slider1,evnt)
        elseif strcmp(evnt.Key,'1') 
            selectNeuron1_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt)

        elseif strcmp(evnt.Key,'2') 
            selectNeuron2_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'3')
            selectNeuron3_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt)
        elseif strcmp(evnt.Key,'4') 
            selectNeuron4_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'5') 
            selectNeuron5_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'6') 
            selectNeuron6_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'7')
            selectNeuron7_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'8') 
            selectNeuron8_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'9');
            selectNeuron9_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'0');
            selectNeuron10_Callback(handles.slider1,evnt,handles);
        elseif strcmp(evnt.Key,'-');
            selectNeuron11_Callback(handles.slider1,evnt,handles);
        elseif strcmp(evnt.Key,'=');
            selectNeuron12_Callback(handles.slider1,evnt,handles);
        elseif strcmp(evnt.Key,'z');
            selectNeuronN_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'x')
           selectNeuronM_Callback(handles.slider1,evnt,handles);
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'return');
            cursorNeuronSelect(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'shift');
            current=get(handles.channelSelect,'Value');
            set(handles.channelSelect,'Value',3-current);
             channelSelect_Callback(handles.channelSelect, evnt, handles)
        elseif strcmp(evnt.Key,'q');
            reclick(handles.slider1,evnt);
        elseif strcmp(evnt.Key,'c');
            exactNeuronSelect(handles.slider1,evnt)
        elseif strcmp(evnt.Key,'h')
            switchShow(handles,evnt)
        end
%         elseif strcmp(evnt.Character,'h')
%             dispFeat=~dispFeat;
%             RefreshDisplayAndPlot;
%             disp('Hide/Show Features');
%         end
%          
        %Ignore the key stroke
function switchShow(handles,eventdata)

show=getappdata(handles.figure1,'show');
if isempty(show)
    show=true;
end
show=~show;
setappdata(handles.figure1,'show',show);
plotter(handles.slider1,eventdata)


% --- Executes on button press in loadFiducials.
function loadFiducials_Callback(hObject, eventdata, handles)
% hObject    handle to loadFiducials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

imFiles=getappdata(handles.figure1,'imFiles');
imFiles=imFiles{1};
if ~isdir(imFiles)
parent=fileparts(imFiles);
else
    parent=imFiles;
end
fiducialFile=uipickfiles('filterspec',parent);

fiducialFile=fiducialFile{1};
fiducialData=load(fiducialFile);

setappdata(handles.figure1,'fiducials', fiducialData.fiducialPoints)
set(handles.timeOffset,'String',num2str(fiducialData.timeOffset))
set(handles.currentFiducialFile,'String',fiducialFile)


function currentFiducialFile_Callback(hObject, eventdata, handles)
% hObject    handle to currentFiducialFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of currentFiducialFile as text
%        str2double(get(hObject,'String')) returns contents of currentFiducialFile as a double


% --- Executes during object creation, after setting all properties.
function currentFiducialFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to currentFiducialFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in previousAnnotated.
function previousAnnotated_Callback(hObject, eventdata, handles)
% hObject    handle to previousAnnotated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fiducialPoints=getappdata(handles.figure1,'fiducials');
currentFrame=getappdata(handles.figure1,'currentFrame');
plotIdx=getappdata(handles.figure1,'cursorTarget');

try
annotated=find(cell2mat(cellfun(@(x) ~isempty(x{plotIdx,1}),fiducialPoints,'uniformOutput',0)));
catch
annotated=find(cell2mat(cellfun(@(x) ~isempty(cell2mat(x)),fiducialPoints,'uniformOutput',0)));
end
nextFrame=annotated((annotated<currentFrame));

if isempty(nextFrame)
    return
end
nextFrame=nextFrame(end);
set(handles.slider1,'Value',max(nextFrame,get(handles.slider1,'min')));
plotter(handles.slider1,eventdata);


% --- Executes on button press in nextAnnotated.
function nextAnnotated_Callback(hObject, eventdata, handles)
% hObject    handle to nextAnnotated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fiducialPoints=getappdata(handles.figure1,'fiducials');
currentFrame=getappdata(handles.figure1,'currentFrame');
plotIdx=getappdata(handles.figure1,'cursorTarget');

try
annotated=find(cell2mat(cellfun(@(x) ~isempty(x{plotIdx,1}),fiducialPoints,'uniformOutput',0)));
catch
annotated=find(cell2mat(cellfun(@(x) ~isempty(cell2mat(x)),fiducialPoints,'uniformOutput',0)));
end

nextFrame=annotated((annotated>currentFrame));
if isempty(nextFrame)
    return
end
nextFrame=nextFrame(1);
set(handles.slider1,'Value',min(nextFrame,get(handles.slider1,'max')));
plotter(handles.slider1,eventdata);


% --- Executes on button press in savingFiducials.
function savingFiducials_Callback(hObject, eventdata, handles)
% hObject    handle to savingFiducials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    set(hObject,'String','SAVING','fontsize', 26, 'BackgroundColor',[1,0,0] )
else
    set(hObject,'String','save fiducials','fontsize', 12, 'BackgroundColor',[1,1,1] )
end


% --- Executes on button press in Continuous.
function Continuous_Callback(hObject, eventdata, handles)
% hObject    handle to Continuous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Continuous


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.figure1,'SelectionType'),'alt')
    cursorNeuronSelect(handles.slider1,eventdata);

end


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.figure1,'SelectionType'),'alt')
    %cursorNeuronSelect(handles.slider1,eventdata);
end



function maxIntensity_Callback(hObject, eventdata, handles)
% hObject    handle to maxIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxIntensity as text
%        str2double(get(hObject,'String')) returns contents of maxIntensity as a double


% --- Executes during object creation, after setting all properties.
function maxIntensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in channelSelect.
function channelSelect_Callback(hObject, eventdata, handles)
% hObject    handle to channelSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channelSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channelSelect

plotter(handles.slider1,eventdata)


% --- Executes during object creation, after setting all properties.
function channelSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
if eventdata.VerticalScrollCount>2
    for i=1:floor(eventdata.VerticalScrollCount/2)
                goUp_Callback(handles.zSlider,eventdata,handles);
    end
elseif eventdata.VerticalScrollCount<-2
    for i=1:floor(abs(eventdata.VerticalScrollCount/2))
                goDown_Callback(handles.zSlider,eventdata,handles);
    end
end



function N_Callback(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of N as text
%        str2double(get(hObject,'String')) returns contents of N as a double

N=str2double(get(hObject,'String'));
NString=num2str(N);
set(handles.selectNeuronN,'String',NString);
setappdata(handles.figure1,'cursorTarget',N);





% --- Executes during object creation, after setting all properties.
function N_CreateFcn(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pointUpdate(handles)
currentClick=datevec(now);
history=getappdata(handles.figure1,'history');
points=getappdata(handles.figure1,'points');
multiplier=1;


if size(history,1)>30
history=cat(1,history(2:end,:),currentClick);
else
    history=cat(1,history,currentClick);
end
setappdata(handles.figure1,'history',history)
if size(history,1)>10

timeIntervalHistory=diff(history,[],1);
timeIntervalHistory=timeIntervalHistory*[0 0 3600*24 3600 60 1]';

shortTimeHistory=mean(timeIntervalHistory(end-9:end));
if size(history,1)>20
longTimeHistory=mean(timeIntervalHistory);
else
  longTimeHistory=inf;
end

if shortTimeHistory<10
    multiplier=multiplier+1;
end
if shortTimeHistory<5
    multiplier=multiplier+3;
end

if longTimeHistory<10
    multiplier=multiplier+5;
end
if longTimeHistory<5
    multiplier=multiplier+1;
end
[shortTimeHistory multiplier]

end

points=points+multiplier;
setappdata(handles.figure1,'points',points);
set(handles.Points,'String',[num2str(points) ' points']);



function xySearch_Callback(hObject, eventdata, handles)
% hObject    handle to xySearch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xySearch as text
%        str2double(get(hObject,'String')) returns contents of xySearch as a double


% --- Executes during object creation, after setting all properties.
function xySearch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xySearch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function zSearch_Callback(hObject, eventdata, handles)
% hObject    handle to zSearch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zSearch as text
%        str2double(get(hObject,'String')) returns contents of zSearch as a double


% --- Executes during object creation, after setting all properties.
function zSearch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zSearch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function refIdx_Callback(hObject, eventdata, handles)
% hObject    handle to refIdx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refIdx as text
%        str2double(get(hObject,'String')) returns contents of refIdx as a double


% --- Executes during object creation, after setting all properties.
function refIdx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refIdx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function filterSize_Callback(hObject, eventdata, handles)
% hObject    handle to filterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filterSize as text
%        str2double(get(hObject,'String')) returns contents of filterSize as a double


% --- Executes during object creation, after setting all properties.
function filterSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in filterOption.
function filterOption_Callback(hObject, eventdata, handles)
% hObject    handle to filterOption (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns filterOption contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filterOption


% --- Executes during object creation, after setting all properties.
function filterOption_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterOption (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function M_Callback(hObject, eventdata, handles)
% hObject    handle to M (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of M as text
%        str2double(get(hObject,'String')) returns contents of M as a double
M=str2double(get(hObject,'String'));
MString=num2str(M);
set(handles.selectNeuronM,'String',MString);
setappdata(handles.figure1,'cursorTarget',M);



% --- Executes during object creation, after setting all properties.
function M_CreateFcn(hObject, eventdata, handles)
% hObject    handle to M (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


