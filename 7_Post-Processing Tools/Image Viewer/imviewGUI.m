function varargout = imviewGUI(varargin)
% Copyright (c) 2017 Paul LaFosse
%
% Created for use by the Klaus Hahn Lab at the University of
% North Carolina at Chapel Hill
%
% Email Contacts:
% Klaus Hahn: khahn@med.unc.edu
% Paul LaFosse: lafosse@ad.unc.edu
%
% This file is part of a comprehensive package, 2dfretimgproc.
% 2dfretimgproc is a free software package that can be modified/
% distributed under the terms described by the GNU General Public 
% License version 3.0. A copy of this license should have been 
% present within the 2dfretimgproc package. If not, please visit 
% the following link to learn more: <http://www.gnu.org/licenses/>.
%
% IMVIEWGUI MATLAB code for imviewGUI.fig
%      IMVIEWGUI, by itself, creates a new IMVIEWGUI or raises the existing
%      singleton*.
%
%      H = IMVIEWGUI returns the handle to a new IMVIEWGUI or the handle to
%      the existing singleton*.
%
%      IMVIEWGUI('CALLBACK',hObject,~,handles,...) calls the local
%      function named CALLBACK in IMVIEWGUI.M with the given input arguments.
%
%      IMVIEWGUI('Property','Value',...) creates a new IMVIEWGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imviewGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imviewGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imviewGUI

% Last Modified by GUIDE v2.5 16-May-2017 14:06:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imviewGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @imviewGUI_OutputFcn, ...
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


% --- Executes just before imviewGUI is made visible.
function imviewGUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imviewGUI (see VARARGIN)

% Choose default command line output for imviewGUI
handles.output = hObject;

% Load additional colormaps
load('maps.mat')
handles.map1 = map1;
handles.map2 = map2;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = imviewGUI_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%% Helper Function
function update_images(hObject,frame)
handles = guidata(hObject);
handles.cur_im = handles.frames_im{frame};
if isempty(get(handles.axes1,'Children')) % is the axes empty (i.e. have any 'Children')
    % sets image
    set(handles.figure1,'CurrentAxes',handles.axes1);
    imagesc(handles.cur_im,'Parent',handles.axes1); % image the current frame in 'handles.axes1'
    set(handles.axes1,'CLim',[handles.CLim_Min, handles.CLim_Max],'XTick',[],'YTick',[],'Box','on'); % set 'handles.axes1' properties
    set(handles.CLim_Max_Tag, 'String', num2str(handles.CLim_Max)); % set the edit box 'CLim_Max_Tag' to the current CLim_val 'maximum'
    set(handles.CLim_Min_Tag, 'String', num2str(handles.CLim_Min)); % set the edit box 'CLim_Min_Tag' to the current CLim_val 'minimum'
%     colorbar;
    axis image % sets the aspect ratio so that the data units are the same in every direction and the plot box fits tightly around the data
else
    imHandle = findobj(handles.axes1,'Type','image');
    set(imHandle,'CData',handles.cur_im); % update the unfiltered image to the current frame
end
guidata(hObject,handles);


%% Listener Functions
function slider1(hObject,~,~)
handles = guidata(hObject);
frame = round(get(handles.slider1,'Value'));
update_images(hObject,frame);
set(handles.edit1,'String',num2str(frame,'%d')); % set the edit box to indicate the current frame number
guidata(hObject, handles);
function slider2(hObject,~,~)
handles = guidata(hObject);
set(handles.slider3,'Max',get(handles.slider2,'Value')-1.0);
set(handles.figure1,'CurrentAxes',handles.axes1);
set(handles.axes1,'CLim',[get(handles.slider3,'Value'),get(handles.slider2,'Value')]);
handles.CLim_Max = get(handles.slider2,'Value');
set(handles.CLim_Max_Tag,'String',num2str(round(get(handles.slider2,'Value')))); % set the edit box 'CLim_Max_Tag' to the current CLim_val 'maximum'
guidata(hObject, handles);
function slider3(hObject,~,~)
handles = guidata(hObject);
set(handles.slider2,'Min',get(handles.slider3,'Value')+1.0);
set(handles.figure1,'CurrentAxes',handles.axes1);
set(handles.axes1,'CLim',[get(handles.slider3,'Value'),get(handles.slider2,'Value')]);
handles.CLim_Min = get(handles.slider3,'Value');
set(handles.CLim_Min_Tag,'String',num2str(round(get(handles.slider3,'Value')))); % set the edit box 'CLim_Min_Tag1' to the current CLim_val 'minimum'
guidata(hObject, handles);

function mousehover(hObject, varargin)
handles = guidata(hObject);
point = get(handles.figure1,'CurrentPoint');
fig1pos = get(handles.figure1,'Position');
conv = [fig1pos(3),fig1pos(4),fig1pos(3),fig1pos(4)];
ax1pos = get(handles.axes1,'Position');
ax1pos = ax1pos.*conv;
frame = round(get(handles.slider1,'Value'));
im = handles.frames_im{frame};
inaxes1 = point(1) >= ax1pos(1) && point(1) <= ax1pos(1) + ax1pos(3) && point(2) >= ax1pos(2) && point(2) <= ax1pos(2) + ax1pos(4);
if inaxes1
    pt = get(handles.axes1,'CurrentPoint');
    if (ceil(pt(1,1)) <= 0 || ceil(pt(1,1)) > size(im,2))
        return;
    elseif (ceil(pt(1,2)) <= 0 || ceil(pt(1,2)) > size(im,1))
        return;
    end
    set(handles.text13,'String',sprintf('Coordinate:\t(%d,%d)\nIntensity Value:\t%.2f',...
        ceil(pt(1,2)),ceil(pt(1,1)),...
        im(ceil(pt(1,2)),ceil(pt(1,1)))));
    return;
else
    set(handles.text13,'String',sprintf('Coordinate:\t(--,--)\nIntensity Value:\t---'));
    return;
end


%#ok<*DEFNU>
%% CLim Edit Boxes
function CLim_Max_Tag_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function CLim_Min_Tag_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function CLim_Max_Tag_Callback(hObject, ~, handles)
handles.CLim_Max = str2double(get(hObject,'String'));  % define in the structure 'handles' the maximum CLim value
set(handles.axes1,'CLim',[handles.CLim_Min, handles.CLim_Max]);  % set the CLim of the current frame
set(handles.axes2,'CLim',[handles.CLim_Min, handles.CLim_Max]);  % set the CLim of the current region frame
guidata(hObject,handles); % update handles structure
function CLim_Min_Tag_Callback(hObject, ~, handles)
handles.CLim_Min = str2double(get(hObject,'String'));  % define in the structure 'handles' the minimum CLim value
set(handles.axes1,'CLim',[handles.CLim_Min, handles.CLim_Max]);  % set the CLim of the current frame
set(handles.axes2,'CLim',[handles.CLim_Min, handles.CLim_Max]);  % set the CLim of the current region frame
guidata(hObject,handles);  % update handles structure


%% Sliders
function slider1_CreateFcn(hObject, ~, ~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider2_CreateFcn(hObject, ~, ~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider3_CreateFcn(hObject, ~, ~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider1_Callback(~, ~, ~)
function slider2_Callback(hObject, ~, handles)
if get(handles.slider2,'Value') == get(handles.slider3,'Value')+1
    set(handles.slider3,'Enable','Off');
else
    set(handles.slider3,'Enable','On');
end
guidata(hObject,handles);
function slider3_Callback(hObject, ~, handles)
if get(handles.slider3,'Value') == get(handles.slider2,'Value')-1
    set(handles.slider2,'Enable','Off');
else
    set(handles.slider2,'Enable','On');
end
guidata(hObject,handles);


%% Pop-up Menus
function popupmenu1_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu1_Callback(hObject, ~, handles)
contents = cellstr(get(hObject,'String'));
cm = contents{get(hObject,'Value')};
if strcmp(cm,'Blue-Red') 
    colormap(handles.map1)
elseif strcmp(cm,'Rainbow+Mask')
    colormap(handles.map2)
else
    colormap(cm);
end


%% Edit Boxes
function edit1_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit2_CreateFcn(hObject, ~, ~)
handles.pausetime = str2double(get(hObject,'String'));
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
guidata(hObject,handles);

function edit1_Callback(hObject, ~, handles)
frame = str2double(get(hObject,'String'));
frame_max = get(handles.slider1,'Max');
if floor(frame) < 1
    set(handles.slider1,'Value',1);
elseif floor(frame) > frame_max
    set(handles.slider1,'Value',frame_max);
elseif isnan(frame)
    set(handles.slider1,'Value',1);
else
    set(handles.slider1,'Value',frame);
end
guidata(hObject,handles);
function edit2_Callback(hObject, ~, handles)
handles.pausetime = str2double(get(hObject,'String'));
guidata(hObject,handles);


%% Menu Tags
function file_tag_Callback(~, ~, ~)

function import_tag_Callback(hObject, ~, handles)

if ~isempty(get(handles.axes1,'Children'))
    set(handles.slider1,'Enable','Off');
    set(handles.slider2,'Enable','Off');
    set(handles.slider3,'Enable','Off');
    set(handles.edit1,'Enable','Off');
    set(handles.edit2,'Enable','Off');
    set(handles.popupmenu1,'Enable','Off');
    set(handles.CLim_Max_Tag,'Enable','Off');
    set(handles.CLim_Min_Tag,'Enable','Off');
    set(handles.uitoggletool1,'Enable','Off');
    set(handles.uitoggletool2,'Enable','Off');
    set(handles.uitoggletool3,'Enable','Off');
    set(handles.moviepush1,'Enable','Off');
end

go = 1;
disp('Select a ".tif" file to open')
[file, path] = uigetfile('*.tif','Select a ".tif" file to open');
if file == 0
    go = 0;
end
if go == 0 && ~isempty(get(handles.axes1,'Children'))
    if handles.num_frames > 1
        set(handles.slider1,'Enable','On');
    end
    set(handles.slider2,'Enable','On');
    set(handles.slider3,'Enable','On');
    set(handles.edit1,'Enable','On');
    set(handles.edit2,'Enable','On');
    set(handles.popupmenu1,'Enable','On');
    set(handles.CLim_Max_Tag,'Enable','On');
    set(handles.CLim_Min_Tag,'Enable','On');
    set(handles.uitoggletool1,'Enable','On');
    set(handles.uitoggletool2,'Enable','On');
    set(handles.uitoggletool3,'Enable','On');
    set(handles.moviepush1,'Enable','On');
    return;
elseif go == 0 && isempty(get(handles.axes1,'Children'))
    return
end

% get image information
info = imfinfo(fullfile(path,file));
handles.width = info(1).Width;
handles.height = info(1).Height;
num_frames = length(info);
handles.num_frames = num_frames;

% initialize image data and load into handles.frames
handles.frames_im = cell(1,num_frames);
maxs = zeros(1,num_frames);
for i = 1:num_frames
   handles.frames_im{i} = imread(fullfile(path,file),i);
   maxs(i) = max(max(handles.frames_im{i}));
end

% set CLim max and min
handles.CLim_Max = max(max(maxs));  % define the maximum value
handles.CLim_Min = 0;               % define the minimum value

% turn enable 'On' for all necessary components
if num_frames > 1
    set(handles.slider1,'Enable','On');
end
set(handles.slider2,'Enable','On');
set(handles.slider3,'Enable','On');
set(handles.edit1,'Enable','On');
set(handles.edit2,'Enable','On');
set(handles.popupmenu1,'Enable','On');
set(handles.CLim_Max_Tag,'Enable','On');
set(handles.CLim_Min_Tag,'Enable','On');
set(handles.uitoggletool1,'Enable','On');
set(handles.uitoggletool2,'Enable','On');
set(handles.uitoggletool3,'Enable','On');
set(handles.moviepush1,'Enable','On');
    
% set max, min, and values of CLim Value sliders
set(handles.slider2,'Max',handles.CLim_Max);    % define slider's max value found in all frames
set(handles.slider2,'Min',handles.CLim_Min + 1.0);
set(handles.slider2,'Value',handles.CLim_Max);  % set the slider's location to the maximum value
set(handles.slider3,'Max',handles.CLim_Max - 1.0);
set(handles.slider3,'Min',handles.CLim_Min);
set(handles.slider3,'Value',handles.CLim_Min);

% set bounds and initialize frame slider
set(handles.slider1,'Min',1);
set(handles.slider1,'Max',num_frames);
set(handles.slider1,'Value',1);
set(handles.slider1,'SliderStep',[1/num_frames,1/num_frames]);
guidata(hObject,handles);

update_images(hObject,round(get(handles.slider1,'Value')));
contents = cellstr(get(handles.popupmenu1,'String'));
cm = contents{get(handles.popupmenu1,'Value')};
colormap(cm);

% set initial max and min pixel values
set(handles.CLim_Max_Tag, 'String', num2str(handles.CLim_Max));
set(handles.CLim_Min_Tag, 'String', num2str(handles.CLim_Min));

% set to display max frames in textbox
set(handles.text1,'String',['of ',num2str(num_frames,'%d')]);

% add listener functions
handles.sl1 = addlistener(handles.slider1,'Value','PostSet',@(src,evnt)slider1(handles.figure1,src,evnt));
handles.sl2 = addlistener(handles.slider2,'Value','PostSet',@(src,evnt)slider2(handles.figure1,src,evnt));
handles.sl3 = addlistener(handles.slider3,'Value','PostSet',@(src,evnt)slider3(handles.figure1,src,evnt));

% set mouse hover functionality
set(handles.figure1,'WindowButtonMotionFcn',@(varargin)mousehover(handles.figure1,varargin));

handles.cur_im = handles.frames_im{1};

guidata(hObject,handles);



%% Movie Button Callback
function moviepush1_ClickedCallback(~, ~, handles)
set(handles.moviepush1,'Enable','Off')
pause_time = handles.pausetime/1000;
frames = get(handles.slider1,'Max');
for f = 1:frames
    set(handles.slider1,'Value',f);
    pause(pause_time);
end
set(handles.slider1,'Value',1);
set(handles.moviepush1,'Enable','On')
