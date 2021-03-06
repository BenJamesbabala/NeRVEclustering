function varargout = VisualizeWormData3D(varargin)
% VISUALIZEWORMDATA3D MATLAB code for VisualizeWormData3D.fig
%      VISUALIZEWORMDATA3D, by itself, creates a new VISUALIZEWORMDATA3D or raises the existing
%      singleton*.
%
%      H = VISUALIZEWORMDATA3D returns the handle to a new VISUALIZEWORMDATA3D or the handle to
%      the existing singleton*.
%
%      VISUALIZEWORMDATA3D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALIZEWORMDATA3D.M with the given input arguments.
%
%      VISUALIZEWORMDATA3D('Property','Value',...) creates a new VISUALIZEWORMDATA3D or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualizeWormData3D_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualizeWormData3D_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualizeWormData3D

% Last Modified by GUIDE v2.5 07-Aug-2014 14:13:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @VisualizeWormData3D_OpeningFcn, ...
    'gui_OutputFcn',  @VisualizeWormData3D_OutputFcn, ...
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


% --- Executes just before VisualizeWormData3D is made visible.
function VisualizeWormData3D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VisualizeWormData3D (see VARARGIN)

% Choose default command line output for VisualizeWormData3D
handles.output = hObject;
hlistener=addlistener(handles.slider1,'ContinuousValueChange',...
    @plotter);
setappdata(handles.slider1,'hlistener',hlistener);
set(handles.slider1,'SliderStep',[1,1]);

hlistener2=addlistener(handles.slider2,'ContinuousValueChange',...
    @plotSlide);
setappdata(handles.slider2,'hlistener',hlistener2);
set(handles.slider2,'SliderStep',[1,1]);



[rpath,parent]=uigetfile('Y:\CommunalCode\3dbrain\','Select Registration File');
registration=load([parent filesep rpath]);


setappdata(0,'registration',registration);

playt.TimerFcn = {@TmrFcn,handles};
playt.BusyMode = 'Queue';
playt.ExecutionMode = 'FixedRate';
playt.Period = 1/2; % set this to 2, then will make the play skip frames accordingly
setappdata(handles.figure1,'playt',playt);
setappdata(handles.figure1,'playTimer',timer(playt));
setappdata(handles.figure1,'FPS',1)
set(handles.framesPerSecond,'String','1')



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VisualizeWormData3D wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VisualizeWormData3D_OutputFcn(hObject, eventdata, handles)
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

    
imFolder=getappdata(0,'imFolder');


if isempty(imFolder)
    imFolder = uigetdir([],'Select MatFile Folder');
    setappdata(0,'imFolder',imFolder);
else
    try
    imFolder = uigetdir(imFolder,'Select MatFile Folder');
    setappdata(0,'imFolder',imFolder);
    catch
    imFolder = uigetdir([],'Select MatFile Folder');
    setappdata(0,'imFolder',imFolder);
    end
end

rawImFolder=uigetdir(imFolder,'Select tif File Folder');

matFiles=dir([imFolder filesep '*.mat']);
setappdata(0,'matFiles',matFiles);



imFiles=dir([rawImFolder filesep '*.tif']);
setappdata(0,'imFiles',imFiles);
setappdata(0,'rawImFolder',rawImFolder);

%setting slider parameters
set(handles.slider1,'Min',1)
if isempty(matFiles)
    set(handles.slider1,'Max',2);
else
    set(handles.slider1,'Max',length(matFiles));
end

set(handles.slider1,'Value',1)

if ~exist([imFolder filesep 'trackOutput.mat'],'file')
runTrack_Callback(hObject, eventdata, handles)

end
    load([imFolder filesep 'trackOutput']);



setappdata(0,'trackOutput',trackOutput);
setappdata(handles.figure1,'currentFrame',1);
set(handles.slider1,'value',1);
set(handles.slider2,'min',1);
set(handles.slider2,'max',max(trackOutput(:,end)));
set(handles.slider2,'value',1);

plotter(handles.slider1,eventdata);








% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%plotter(handles.slider1,eventdata);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in channelSelect.
function channelSelect_Callback(hObject, eventdata, handles)
% hObject    handle to channelSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotter(handles.slider1,eventdata);
% Hints: contents = cellstr(get(hObject,'String')) returns channelSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channelSelect


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






function plotter(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));
timeStep=str2double(get(handles.timeStep,'string'));
smoothWindow=str2double(get(handles.smoothingWindow,'String'));
startTime=str2double(get(handles.startTime,'String'));
normalizeFlag=get(handles.normalizeButton,'value');
imFolder=getappdata(0,'imFolder');
iImage=round(get(handles.slider1,'Value'));
set(handles.FrameIdx,'string',[num2str(iImage*timeStep,'%6.2f') 's']);

trackData=getappdata(0,'trackOutput');

matFiles=getappdata(0,'matFiles');
imFiles=getappdata(0,'imFiles');
rawImFolder=getappdata(0,'rawImFolder');

 wormMask=load([imFolder filesep matFiles(iImage).name],'wormMask');
 if isfield(wormMask,'wormMask')
wormMask=wormMask.wormMask;
R=getappdata(0,'registration');

if ~isempty(R)
rect1=R.rect1;
rect2=R.rect2;
t_concord=R.t_concord;
Rsegment=R.Rsegment;
padRegion=R.padRegion;
temp=double(imread([rawImFolder filesep imFiles(iImage).name],'tif'));
temp=pixelIntensityCorrection(temp);
temp_activity=temp((rect2(2)+1):rect2(4),(1+rect2(1)):rect2(3));
worm=temp((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3));
temp_activity=imwarp(temp_activity,t_concord,'OutputView',Rsegment);
temp_activity(padRegion)=median(temp_activity(~padRegion));
activity=(temp_activity);%bpass_jn(temp_activity,1,[40,40]);
hold(handles.axes1,'off')
%clear current axes
arrayfun(@(x) delete(x),get(handles.axes1,'children'))

switch get(handles.channelSelect,'value')
    case 1
baseImg=worm;
    case 2
baseImg=activity;
end
end
setappdata(handles.figure1,'baseImg',baseImg);
newContrast=getappdata(handles.figure1,'newContrast');
if isempty(newContrast)
    newContrast=[min(baseImg(:)),max(baseImg(:))];
end
baseImg(baseImg<newContrast(1)) = newContrast(1);
baseImg(baseImg>newContrast(2)) = newContrast(2);
baseImg = (baseImg-newContrast(1))./diff(newContrast);
ax1=imagesc(baseImg,'parent',handles.axes1);
hold(handles.axes1,'on')

tracks=trackData(trackData(:,end-1)==iImage,:);
scat=scatter(handles.axes1,tracks(:,1),tracks(:,2),'rx');
currentCentroids=tracks(:,[1,2,size(tracks,2)]);
setappdata(handles.figure1,'currentCentroids',currentCentroids);

hold(handles.axes1,'on')
axis(handles.axes1,'equal');

text(tracks(:,1),tracks(:,2),cellstr(num2str(tracks(:,end))),'VerticalAlignment'...
    ,'bottom', 'HorizontalAlignment','right','color',[1 1 1],'parent',handles.axes1);



B=bwboundaries(wormMask);
for i=1:length(B)
    b=B{i};
    plot(handles.axes1,b(:,2),b(:,1),'b')
end
hold(handles.axes1,'off')
if get(handles.showAll,'value')
%show heatmap of all tracks
activityMat=getappdata(handles.figure1,'activityMat');
imagesc(activityMat,'parent',handles.axes2);
else
    
%display point on axis 2
displayIdx=get(handles.DisplayIdx,'data');
plotIdx=[displayIdx{:,1}];
plotIdx=plotIdx(~isnan(plotIdx) & plotIdx~=0);
hold(handles.axes2,'off');

switch get(handles.plotChannel,'value')
    case 1
        output=trackData(:,4);
    case 2
        output=trackData(:,3);
      
    case 3
        output=trackData(:,3)./trackData(:,4);
end
setappdata(handles.figure1,'output',output);

switch get(handles.plotChannel2,'value')
    case 1
        output2= nan*ones(size(trackData(:,1)));
    case 2
        output2=trackData(:,4);
    case 3
        output2=trackData(:,3);
    case 4
        output2=trackData(:,3)./trackData(:,4);
    case 5
        output2=trackData(:,1);
end
setappdata(handles.figure1,'output',output);

output(trackData(:,end-1)<startTime)=nan;
 output=normalizeRange(output);
 %output=output/median(output);

for i=1:length(plotIdx);
    idx=plotIdx(i);
    t=trackData((trackData(:,end)==idx),end-1);
    a=output((trackData(:,end)==idx));
    a2=output2((trackData(:,end)==idx));
    a=a(t>startTime);
    a2=a2(t>startTime);
    t=t(t>startTime);
    if normalizeFlag
            a=normalizeRange(smooth(a,smoothWindow))+i-1;
    else
        
    a=(smooth(a,smoothWindow))+i-1;
    a2=normalizeRange(smooth(a2,smoothWindow))+i-1;
    end
    t=t*timeStep;
    plot(handles.axes2,t,a);
hold(handles.axes2,'on');
plot(handles.axes2,t,a2,'g');
end




subIdx=ismember(tracks(:,end),plotIdx);
text(tracks(subIdx,1),tracks(subIdx,2),cellstr(num2str(tracks(subIdx,end))),'VerticalAlignment'...
    ,'bottom', 'HorizontalAlignment','right','color',[0 1 0],'parent',handles.axes1);


hold(handles.axes2,'on');
h=getappdata(0,'scatter');
for iPlot=1:length(plotIdx); 
    try
    delete(h(iPlot));
    catch
    end
    
    idx=plotIdx(iPlot);
    t=trackData((trackData(:,end)==idx),end-1);
    a=output((trackData(:,end)==idx));
        a=a(t>startTime);
    t=t(t>startTime);
    t=t*timeStep;
    if normalizeFlag
    a=normalizeRange(smooth(a,smoothWindow))+iPlot-1;
    else
    a=(smooth(a,smoothWindow))+iPlot-1;
    end
    a=a(t==(iImage*timeStep));
    if sum(a)
    h(iPlot)=scatter(handles.axes2,(iImage*timeStep),a,'r','fill');
    end
    
hold(handles.axes2,'on');
end
setappdata(0,'scatter',h);
end
set(handles.currentFolder,'String',imFolder);


 else
     display('no data in this matfile');
 end
 


function smoothingWindow_Callback(hObject, eventdata, handles)
% hObject    handle to smoothingWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 plotter(handles.slider1,eventdata);

% Hints: get(hObject,'String') returns contents of smoothingWindow as text
%        str2double(get(hObject,'String')) returns contents of smoothingWindow as a double


% --- Executes during object creation, after setting all properties.
function smoothingWindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothingWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function startTime_Callback(hObject, eventdata, handles)
% hObject    handle to startTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 plotter(handles.slider1,eventdata);
% Hints: get(hObject,'String') returns contents of startTime as text
%        str2double(get(hObject,'String')) returns contents of startTime as a double


% --- Executes during object creation, after setting all properties.
function startTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
FPS=getappdata(handles.figure1,'FPS');
set(handles.slider1,'value',get(handles.slider1,'value')-FPS);
setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));
plotter(handles.slider1,eventdata)


% --- Executes on button press in goForward.
function goForward_Callback(hObject, eventdata, handles)
% hObject    handle to goForward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FPS=getappdata(handles.figure1,'FPS');
set(handles.slider1,'value',get(handles.slider1,'value')+FPS);
setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));
plotter(handles.slider1,eventdata)




% --- Executes on button press in playVideo.
function playVideo_Callback(hObject, eventdata, handles)
% hObject    handle to playVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button_state = get(hObject,'Value');
% disp(button_state);
% disp(get(hObject,'Max'));
% disp(get(hObject,'Min'));
if button_state == get(hObject,'Max')
    % Toggle button is pressed, take appropriate action
    set(hObject,'String','Stop');
    set(hObject,'ForegroundColor',[1 0 0]);
    
    %     set(handles.cursortoggle,'State','off'); % having cursor on creates errs
    start(getappdata(handles.figure1,'playTimer'))
elseif button_state == get(hObject,'Min')
    % Toggle button is not pressed, take appropriate action
    set(hObject,'String','Play');
    set(hObject,'ForegroundColor',[0 1 0]);
   
    stop(getappdata(handles.figure1,'playTimer'))
    %     set(handles.cursortoggle,'State','on'); % cursor on is default!
end

% Hint: get(hObject,'Value') returns toggle state of playVideo



function framesPerSecond_Callback(hObject, eventdata, handles)
% hObject    handle to framesPerSecond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FPS=str2double(get(handles.framesPerSecond,'String'));
setappdata(handles.figure1,'FPS',FPS)


% Hints: get(hObject,'String') returns contents of framesPerSecond as text
%        str2double(get(hObject,'String')) returns contents of framesPerSecond as a double


% --- Executes during object creation, after setting all properties.
function framesPerSecond_CreateFcn(hObject, eventdata, handles)
% hObject    handle to framesPerSecond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TmrFcn(src,event,handles)
% pull appdata from the handles structure
 
CurrentFrame = getappdata(handles.figure1,'currentFrame');
% set(handles.slider1,'Value',CurrentFrame)
%CurrentFrame=1;
totalFrames = get(handles.slider1,'Max');
frameStep=str2double(get(handles.framesPerSecond,'string'))/2;
setappdata(handles.figure1,'currentFrame',CurrentFrame+frameStep);
loop = false;
 
% at some point, include the ability to loop
% loop = get(handles.loop,'Value');
% if the current frame is less than the total, increment frame by one
if CurrentFrame < totalFrames
    set(handles.slider1,'Value',floor(CurrentFrame+frameStep))
    % otherwise, if looping, reset to 1
    % elseif loop == get(handles.loop,'Max')
elseif loop
    set(handles.slider1,'Value',1)
    % otherwise, stop playback
else
    set(handles.playVideo_Callback,'Value',get(handles.togglePlay,'Min'));
    playVideo_Callback(handles.togglePlay, event, handles);
end
plotter(handles.slider1,event)
if get(handles.makeMovie,'value')
    frame=getframe(handles.axes1);
    writerObj=getappdata(handles.figure1,'writerObj');
    writeVideo(writerObj,frame)
    
    
    frame2=getframe(handles.axes2);
    writerObj2=getappdata(handles.figure1,'writerObj2');
    writeVideo(writerObj2,frame2)

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
cursorNeuronSelect(hObject,eventdata)
displayIdx=get(handles.DisplayIdx,'data');
displayIdx{1,1}=round(get(handles.slider2,'value'));
set(handles.slider2,'value',displayIdx{1,1});


% --- Executes on button press in selectNeuron2.
function selectNeuron2_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',2);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron3.
function selectNeuron3_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',3);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron4.
function selectNeuron4_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',4);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron5.
function selectNeuron5_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',5);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron6.
function selectNeuron6_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',6);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron7.
function selectNeuron7_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',7);
cursorNeuronSelect(hObject,eventdata)

% --- Executes on button press in selectNeuron8.
function selectNeuron8_Callback(hObject, eventdata, handles)
% hObject    handle to selectNeuron8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(handles.figure1,'cursorTarget',8);
cursorNeuronSelect(hObject,eventdata)

function cursorNeuronSelect(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));
plotIdx=getappdata(handles.figure1,'cursorTarget');
currentCentroids=getappdata(handles.figure1,'currentCentroids');

[xselect,yselect]=ginput(1);
xRange=xlim(handles.axes1);
yRange=ylim(handles.axes1);
if xselect>xRange(1) && xselect< xRange(2) && yselect>yRange(1) && yselect<yRange(2);
minD=pdist2([xselect,yselect],currentCentroids(:,1:2),'euclidean','smallest',1);
pointIdx=find(minD==min(minD),1,'first');
pointIdx=currentCentroids(pointIdx,3);
else
    pointIdx=nan;
end

displayIdx=get(handles.DisplayIdx,'data');
displayIdx{plotIdx,1}=pointIdx;
set(handles.DisplayIdx,'data',displayIdx);
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


% --- Executes on button press in sortPlots.
function sortPlots_Callback(hObject, eventdata, handles)
% hObject    handle to sortPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
displayIdx=get(handles.DisplayIdx,'data');
plotIdx=[displayIdx{:,1}];
plotIdx=sort(unique(plotIdx));
clearPlots_Callback(hObject,eventdata,handles);
for i =1:length(plotIdx);
    displayIdx{i,1}=plotIdx(i);
end
for i=length(plotIdx)+1:length(displayIdx)
    displayIdx{i,1}=[];
end


set(handles.DisplayIdx,'data',displayIdx);
plotter(handles.slider1,'eventdata');


function plotSlide(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));
displayIdx=get(handles.DisplayIdx,'data');
displayIdx{1,1}=round(get(handles.slider2,'value'));
set(handles.DisplayIdx,'data',displayIdx);
plotter(handles.slider1,'eventdata');


% --- Executes on button press in goForward2.
function goForward2_Callback(hObject, eventdata, handles)
% hObject    handle to goForward2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)set(handles.slider1,'value',get(handles.slider1,'value')+1);
set(handles.slider2,'value',min(get(handles.slider2,'value')+1,get(handles.slider2,'max')));
plotSlide(hObject,eventdata)


% --- Executes on button press in runTrack.
function runTrack_Callback(hObject, eventdata, handles)
% hObject    handle to runTrack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    minDist=30;
    minTrack=800;
    params.mem=30;
imFolder=getappdata(0,'imFolder');

matFiles=dir([imFolder filesep '*.mat']);
setappdata(0,'matFiles',matFiles);
imFiles=dir([imFolder filesep '*.tif']);
setappdata(0,'imFiles',imFiles);

trackData=[];
trackIdx=0;
progressbar(0);
for imat=1:1:length(matFiles)
    trackIdx=trackIdx+1;
    load([imFolder filesep matFiles(imat).name]);
    tracks=[centroids,Gintensities,Rintensities,trackIdx*ones(size(Gintensities))];
    trackData=[trackData;tracks];
    progressbar((imat)/length(matFiles));
end

    params.dim=size(centroids,2);

for i=1:minDist*.5
try
trackOutput=track(trackData,minDist/i,params);
break
catch
    display(['reducing minDist by factor of ' num2str(i)]);
end
end
    
trackLengths=accumarray(trackOutput(:,end),ones(size(trackOutput(:,end))));

badtracks=find(trackLengths<minTrack);
badtracks=any(bsxfun(@eq, trackOutput(:,end),badtracks'),2);

trackOutput(badtracks,:)=[];
%  trackLengths=accumarray(trackOutput(:,end),ones(size(trackOutput(:,end))));
[ trackIdx,ia,ib]=unique(trackOutput(:,end));
trackOutput(:,end)=ib;

nTracks=max(trackOutput(:,end));
nTime=max(trackOutput(:,end-1));
for iTrack=1:nTracks
    t=trackOutput((trackOutput(:,end)==iTrack),end-1);
    centroid=trackOutput((trackOutput(:,end)==iTrack),1:3);
    green=trackOutput((trackOutput(:,end)==iTrack),4);
    red=trackOutput((trackOutput(:,end)==iTrack),5);
    
    cellOutput(iTrack).time=t;
    cellOutput(iTrack).centroid=centroid;
    cellOutput(iTrack).green=green;
    cellOutput(iTrack).red=red;
    
    
end

save([imFolder filesep 'trackOutput'],'trackOutput','cellOutput')








% --- Executes on selection change in plotChannel2.
function plotChannel2_Callback(hObject, eventdata, handles)
% hObject    handle to plotChannel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotter(handles.slider1,'eventdata');

% Hints: contents = cellstr(get(hObject,'String')) returns plotChannel2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plotChannel2


% --- Executes during object creation, after setting all properties.
function plotChannel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotChannel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function movieTitle_Callback(hObject, eventdata, handles)
% hObject    handle to movieTitle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of movieTitle as text
%        str2double(get(hObject,'String')) returns contents of movieTitle as a double


% --- Executes during object creation, after setting all properties.
function movieTitle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to movieTitle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in makeMovie.
function makeMovie_Callback(hObject, eventdata, handles)
% hObject    handle to makeMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button_state=get(hObject,'value');
ax1movie=[get(handles.movieTitle,'String') '1'];
ax2movie=[get(handles.movieTitle,'String') '2'];
startTime=str2double(get(handles.startTime,'String'));
imFolder=getappdata(0,'imFolder');

if button_state
writerObj=VideoWriter([imFolder filesep ax1movie]);
writerObj2=VideoWriter([imFolder filesep ax2movie]);

setappdata(handles.figure1,'writerObj',writerObj);
setappdata(handles.figure1,'writerObj2',writerObj2);

open(writerObj);
open(writerObj2);

set(handles.slider1,'value',startTime)
set(handles.playVideo,'value',1);
%playVideo_Callback(handles.playVideo, eventdata, handles)
set(hObject,'String','Rec');
else
    writerObj=getappdata(handles.figure1,'writerObj');
    writerObj2=getappdata(handles.figure1,'writerObj2');
    
    close(writerObj);
    close(writerObj2);
    
    set(handles.playVideo,'value',0);
playVideo_Callback(handles.playVideo, eventdata, handles)
set(hObject,'String','Make Movie')
end


% --- Executes on button press in normalizeButton.
function normalizeButton_Callback(hObject, eventdata, handles)
% hObject    handle to normalizeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of normalizeButton
plotter(handles.slider1,eventdata);



function timeStep_Callback(hObject, eventdata, handles)
% hObject    handle to timeStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeStep as text
%        str2double(get(hObject,'String')) returns contents of timeStep as a double


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


% --- Executes on button press in showAll.
function showAll_Callback(hObject, eventdata, handles)
% hObject    handle to showAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
trackData=getappdata(0,'trackOutput');
smoothWindow=str2double(get(handles.smoothingWindow,'String'));
startTime=str2double(get(handles.startTime,'string'));
normalizeFlag=get(handles.normalizeButton,'value');


switch get(handles.plotChannel,'value')
    case 1
        output=trackData(:,4);
    case 2
        output=trackData(:,3);
      
    case 3
        output=trackData(:,3)./trackData(:,4);
end

output(trackData(:,end-1)<startTime)=nan;
 output=normalizeRange(output);
 %output=output/median(output);
nTracks=max(trackData(:,end));
nTime=max(trackData(:,end-1));
activityMat=zeros(nTracks,nTime);
for i=1:nTracks
    t=trackData((trackData(:,end)==i),end-1);
    a=output((trackData(:,end)==i));
    a=a(t>startTime);
    t=t(t>startTime);        
    a=(smooth(a,smoothWindow));
    if normalizeFlag
        a=normalizeRange(a);
    end
    
    activityMat(i,t)=a;
    
end
 setappdata(handles.figure1,'activityMat',activityMat);
 cla(handles.axes2);
 plotter(handles.slider1,eventdata);
   
% Hint: get(hObject,'Value') returns toggle state of showAll


% --- Executes on button press in alignmentSelect.
function alignmentSelect_Callback(hObject, eventdata, handles)
% hObject    handle to alignmentSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



[rpath,parent]=uigetfile('Y:\CommunalCode\3dbrain\');
registration=load([parent filesep rpath]);


setappdata(0,'registration',registration);
