function varargout = VisualizeWormData(varargin)
% VISUALIZEWORMDATA MATLAB code for VisualizeWormData.fig
%      VISUALIZEWORMDATA, by itself, creates a new VISUALIZEWORMDATA or raises the existing
%      singleton*.
%
%      H = VISUALIZEWORMDATA returns the handle to a new VISUALIZEWORMDATA or the handle to
%      the existing singleton*.
%
%      VISUALIZEWORMDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALIZEWORMDATA.M with the given input arguments.
%
%      VISUALIZEWORMDATA('Property','Value',...) creates a new VISUALIZEWORMDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualizeWormData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualizeWormData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualizeWormData

% Last Modified by GUIDE v2.5 27-Apr-2014 01:12:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @VisualizeWormData_OpeningFcn, ...
    'gui_OutputFcn',  @VisualizeWormData_OutputFcn, ...
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


% --- Executes just before VisualizeWormData is made visible.
function VisualizeWormData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VisualizeWormData (see VARARGIN)

% Choose default command line output for VisualizeWormData
handles.output = hObject;
hlistener=addlistener(handles.slider1,'ContinuousValueChange',...
    @plotter);
setappdata(handles.slider1,'hlistener',hlistener);
set(handles.slider1,'SliderStep',[1,1]);
registration=load('Y:\CommunalCode\3dbrain\registration');
setappdata(0,'registration',registration);

playt.TimerFcn = {@TmrFcn,handles};
playt.BusyMode = 'Queue';
playt.ExecutionMode = 'FixedRate';
playt.Period = 1/2; % set this to 2, then will make the play skip frames accordingly
setappdata(handles.figure1,'playt',playt);
setappdata(handles.figure1,'playTimer',timer(playt));



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VisualizeWormData wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VisualizeWormData_OutputFcn(hObject, eventdata, handles)
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
    minDist=30;
    minTrack=800;
    params.mem=30;
    
imFolder=getappdata(0,'imFolder');
if isempty(imFolder)
    imFolder = uigetdir();
    setappdata(0,'imFolder',imFolder);
else
    imFolder = uigetdir(imFolder);
    setappdata(0,'imFolder',imFolder);
end

matFiles=dir([imFolder filesep 'stackdata' filesep '*.mat']);
setappdata(0,'matFiles',matFiles);
imFiles=dir([imFolder filesep '*.tif']);
setappdata(0,'imFiles',imFiles);

%setting slider parameters
set(handles.slider1,'Min',1)
if isempty(matFiles)
    set(handles.slider1,'Max',2);
else
    set(handles.slider1,'Max',length(matFiles));
end

set(handles.slider1,'Value',1)

trackData=[];
trackIdx=0;
progressbar(0);
for imat=1:1:length(matFiles)
    trackIdx=trackIdx+1;
    load([imFolder filesep 'stackdata' filesep matFiles(imat).name]);
    tracks=[centroids,Gintensities,Rintensities,trackIdx*ones(size(Gintensities))];
    trackData=[trackData;tracks];
    progressbar((imat)/length(matFiles));
end

    params.dim=size(centroids,2);

try
trackOutput=track(trackData,minDist,params);
catch
    trackOutput=track(trackData,minDist/2,params);

end

trackLengths=accumarray(trackOutput(:,end),ones(size(trackOutput(:,end))));

badtracks=find(trackLengths<minTrack);
badtracks=any(bsxfun(@eq, trackOutput(:,end),badtracks'),2);

trackOutput(badtracks,:)=[];
%  trackLengths=accumarray(trackOutput(:,end),ones(size(trackOutput(:,end))));
[ trackIdx,ia,ib]=unique(trackOutput(:,end));
trackOutput(:,end)=ib;

setappdata(0,'trackOutput',trackOutput);
setappdata(handles.figure1,'currentFrame',1);
set(handles.slider1,'value',1);
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



% --- Executes on button press in plotSignal.
function plotSignal_Callback(hObject, eventdata, handles)
% hObject    handle to plotSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
trackData=getappdata(0,'trackOutput');
displayIdx=get(handles.DisplayIdx,'data');
smoothWindow=str2double(get(handles.smoothingWindow,'String'));
startTime=str2double(get(handles.startTime,'String'));
plotIdx=[(displayIdx{:,1})];
plotIdx=plotIdx(~isnan(plotIdx));
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

for i=1:length(plotIdx);
    idx=plotIdx(i);
    t=trackData((trackData(:,end)==idx),end-1);
    a=output((trackData(:,end)==idx));
    a=a(t>startTime);
    t=t(t>startTime);
    a=normalizeRange(smooth(a,smoothWindow))+i-1;
    plot(handles.axes2,t,a);
hold(handles.axes2,'on');
end


function plotter(hObject,eventdata)
handles=guidata(get(hObject,'Parent'));
R=getappdata(0,'registration');
rect1=R.rect1;
rect2=R.rect2;
t_concord=R.t_concord;
Rsegment=R.Rsegment;
padRegion=R.padRegion;



smoothWindow=str2double(get(handles.smoothingWindow,'String'));
startTime=str2double(get(handles.startTime,'String'));

imFolder=getappdata(0,'imFolder');
iImage=round(get(handles.slider1,'Value'));
trackData=getappdata(0,'trackOutput');

matFiles=getappdata(0,'matFiles');
imFiles=getappdata(0,'imFiles');

wormMask=load([imFolder filesep 'stackdata' filesep matFiles(iImage).name],'wormMask');
wormMask=wormMask.wormMask;
if 1

temp=double(imread([imFolder filesep imFiles(iImage).name],'tif'));
temp=pixelIntensityCorrection(temp);
temp_activity=temp((rect2(2)+1):rect2(4),(1+rect2(1)):rect2(3));
worm=temp((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3));
temp_activity=imwarp(temp_activity,t_concord,'OutputView',Rsegment);
temp_activity(padRegion)=median(temp_activity(~padRegion));
activity=normalizeRange(temp_activity);%bpass_jn(temp_activity,1,[40,40]);
worm=normalizeRange(worm);
hold(handles.axes1,'off')
%clear current axes
arrayfun(@(x) delete(x),get(handles.axes1,'children'))

switch get(handles.channelSelect,'value')
    case 1
ax1=imagesc(worm,'parent',handles.axes1);
    case 2
ax1=imagesc(activity,'parent',handles.axes1);
end
hold(handles.axes1,'on')
end
tracks=trackData(trackData(:,end-1)==iImage,:);
scat=scatter(handles.axes1,tracks(:,1),tracks(:,2),'rx');
hold(handles.axes1,'on')
axis(handles.axes1,'equal');
text(tracks(:,1),tracks(:,2),cellstr(num2str(tracks(:,end))),'VerticalAlignment'...
    ,'bottom', 'HorizontalAlignment','right','color',[1 1 1],'parent',handles.axes1);

B=bwboundaries(wormMask);
for i=1:length(B)
    b=B{i};
    plot(handles.axes1,b(:,2),b(:,1),'black')
end
hold(handles.axes1,'off')

%display point on axis 2
displayIdx=get(handles.DisplayIdx,'data');
plotIdx=str2double(displayIdx(:,1));
plotIdx=plotIdx(~isnan(plotIdx));
hold(handles.axes2,'on');
h=getappdata(0,'scatter');
output=getappdata(handles.figure1,'output');
for iPlot=1:length(plotIdx); 
    try
    delete(h(iPlot));
    catch
    end
    
    idx=plotIdx(iPlot);
    t=trackData((trackData(:,end)==idx),end-1);
    a=trackData((output(:,end)==idx));
        a=a(t>startTime);
    t=t(t>startTime);
    a=normalizeRange(smooth(a,smoothWindow))+iPlot-1;
    a=a(t==iImage);
    if sum(a)
    h(iPlot)=scatter(handles.axes2,iImage,a,'r','fill');
    end
    
hold(handles.axes2,'on');
end
setappdata(0,'scatter',h);





function smoothingWindow_Callback(hObject, eventdata, handles)
% hObject    handle to smoothingWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
set(handles.slider1,'value',get(handles.slider1,'value')-1);
setappdata(handles.figure1,'currentFrame',get(handles.slider1,'value'));
plotter(handles.slider1,eventdata)


% --- Executes on button press in goForward.
function goForward_Callback(hObject, eventdata, handles)
% hObject    handle to goForward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.slider1,'value',get(handles.slider1,'value')+1);
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


% --- Executes on selection change in plotChannel.
function plotChannel_Callback(hObject, eventdata, handles)
% hObject    handle to plotChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotSignal_Callback(hObject, eventdata, handles)
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
