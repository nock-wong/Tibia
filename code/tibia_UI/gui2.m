function varargout = gui2(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 02-Feb-2012 07:14:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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

% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
clc;
addpath(genpath(pwd));
% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Begins load DICOM prompt and sets initial conditions

function load_dicom_Callback(hObject, eventdata, handles)
homeDir= pwd;

% Locate DICOM directory
dicomDir = uigetdir(pwd);

% Process and Import DICOMDIR
dicom = loaddcmdir(dicomDir);
images = dicom.Images;
info = dicominfo(char(images(1)));

% Load raw axial view slides
axial = zeros(info.Columns, info.Rows,size(images,1));
axial(:,:,1) = dicomread(info);
for i = 2:size(images,1)
    info = dicominfo(char(images(i)));
    axial(:,:,i) = dicomread(info);
end
cd(dicomDir);

% Generate coronal views
thickness = info.SliceThickness;
px_size = info.PixelSpacing(1);
divs = round(size(axial,3)/px_size);
coronal = zeros(divs,info.Rows,info.Columns);
for m = 1:divs
    position = m*px_size(1);
    low = floor(position);
    if low == 0
        low = 1;
    end
    high = ceil(position);
    if high > size(axial,3)
        high = size(axial,3);
    end
    % linear interpolation between adjacent axial scans
    coronal(m,:,:) = (axial(:,:,low)+(axial(:,:,high)-axial(:,:,low))*(position-low))';
end

% Generate sagittal views
thickness = info.SliceThickness;
px_size = info.PixelSpacing(1);
divs = round(size(axial,3)/px_size);
sagittal = zeros(divs,info.Columns,info.Rows);
for m = 1:divs
    position = m*px_size(1);
    low = floor(position);
    if low == 0
        low = 1;
    end
    high = ceil(position);
    if high > size(axial,3)
        high = size(axial,3);
    end
    % linear interpolation between adjacent axial scans
    sagittal(m,:,:) = (axial(:,:,low)+(axial(:,:,high)-axial(:,:,low))*(position-low));
end

% Update properties of sliders based on range of CT scan
set(handles.slider_axial_pos,'Min',1);
set(handles.slider_axial_pos,'Max',size(axial,3));
set(handles.slider_axial_pos,'Value',round((1+size(axial,3))/2));
set(handles.slider_axial_pos,'SliderStep',[1/(size(axial,3)-1) 5/(size(axial,3)-1)]);

set(handles.slider_coronal_pos,'Min',1);
set(handles.slider_coronal_pos,'Max',size(coronal,3));
set(handles.slider_coronal_pos,'Value',round((1+size(coronal,3))/2));
set(handles.slider_coronal_pos,'SliderStep',[1/(size(coronal,3)-1) 5/(size(coronal,3)-1)]);

set(handles.slider_sagittal_pos,'Min',1);
set(handles.slider_sagittal_pos,'Max',size(sagittal,3));
set(handles.slider_sagittal_pos,'Value',round((1+size(sagittal,3))/2));
set(handles.slider_sagittal_pos,'SliderStep',[1/(size(sagittal,3)-1) 5/(size(sagittal,3)-1)]);

% Plot initial views
set(gcf,'CurrentAxes',handles.plot_axial);
imshow(axial(:,:,get(handles.slider_axial_pos,'Value')),[0,3071]);
label = sprintf('%d:%d',get(handles.slider_axial_pos,'Value'),get(handles.slider_axial_pos,'Max'));
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_axial = imline(gca,double([(info.Columns)/2 0+50; (info.Columns)/2 (info.Rows)-50]));

set(gcf,'CurrentAxes',handles.plot_coronal);
imshow(coronal(:,:,get(handles.slider_coronal_pos,'Value')),[0,3071]);
label = sprintf('%d:%d',get(handles.slider_coronal_pos,'Value'),get(handles.slider_coronal_pos,'Max'));
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_coronal = imline(gca,double([(info.Columns)/2 0+50; (info.Columns)/2 size(coronal,1)-50]));

set(gcf,'CurrentAxes',handles.plot_sagittal);
imshow(sagittal(:,:,get(handles.slider_sagittal_pos,'Value')),[0,3071]);
label = sprintf('%d:%d',get(handles.slider_sagittal_pos,'Value'),get(handles.slider_sagittal_pos,'Max'));
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_sagittal = imline(gca,double([(info.Columns)/2 0+50; (info.Columns)/2 size(sagittal,1)-50]));

% Saves handles
handles.axial_data = axial;
handles.coronal_data = coronal;
handles.sagittal_data = sagittal;
handles.info_data = info;
guidata(hObject,handles);

clear axial coronal sagittal thickness px_size divs images dicom reformat_axial;

% --- Executes on slider movement.
function slider_axial_pos_Callback(hObject, eventdata, handles)
api = iptgetapi(handles.reformat_axial);
pos = api.getPosition();
index = round(get(hObject,'Value'));    % ensure integer index
set(hObject,'Value',index);
set(gcf,'CurrentAxes',handles.plot_axial);
label = sprintf('%d:%d',index,get(hObject,'Max'));
imshow(handles.axial_data(:,:,index),[0,3071]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_axial = imline(gca,pos);
guidata(hObject,handles);

% --- Executes on slider movement.
function slider_coronal_pos_Callback(hObject, eventdata, handles)
api = iptgetapi(handles.reformat_coronal);
pos = api.getPosition();
index = round(get(hObject,'Value'));    % ensure integer index
set(hObject,'Value',index);
set(gcf,'CurrentAxes',handles.plot_coronal);
label = sprintf('%d:%d',index,get(hObject,'Max'));
imshow(handles.coronal_data(:,:,index),[0,3071]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_coronal = imline(gca,pos);
guidata(hObject,handles);


% --- Executes on slider movement.
function slider_sagittal_pos_Callback(hObject, eventdata, handles)
api = iptgetapi(handles.reformat_sagittal);
pos = api.getPosition();
index = round(get(hObject,'Value'));    % ensure integer index
set(hObject,'Value',index);
set(gcf,'CurrentAxes',handles.plot_sagittal);
label = sprintf('%d:%d',index,get(hObject,'Max'));
imshow(handles.sagittal_data(:,:,index),[0,3071]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_sagittal = imline(gca,pos);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function slider_axial_pos_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function slider_coronal_pos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_coronal_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function slider_sagittal_pos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_sagittal_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in Reformat.
function Reformat_Callback(hObject, eventdata, handles)
% Load angle
api = iptgetapi(handles.reformat_axial);
pos_axial = api.getPosition();
theta_axial = getAngle(pos_axial);

% Rotate images
axial_temp = handles.axial_data;
for i = 1:size(handles.axial_data,3)
    axial_temp(:,:,i) = imrotate(axial_temp(:,:,i),-180/pi*theta_axial,'bilinear','crop');
end
handles.axial_data = axial_temp;

% Replot image
set(gcf,'CurrentAxes',handles.plot_axial);
imshow(handles.axial_data(:,:,get(handles.slider_axial_pos,'Value')),[0,3071]);
label = sprintf('%d:%d',get(handles.slider_axial_pos,'Value'),get(handles.slider_axial_pos,'Max'));
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_axial = imline(gca,double([(handles.info_data.Columns)/2 0+50; (handles.info_data.Columns)/2 (handles.info_data.Rows)-50]));

% Update data
guidata(hObject,handles);




% api = iptgetapi(handles.reformat_coronal);
% pos_coronal = api.getPosition();
% theta_coronal = getAngle(pos_coronal);
% 
% api = iptgetapi(handles.reformat_sagittal);
% pos_sagittal = api.getPosition();
% theta_sagittal = getAngle(pos_sagittal);

function theta = getAngle(pos)
x1 = pos(1,1);
y1 = -1*pos(1,2);
x2 = pos(2,1);
y2 = -1*pos(2,2);
if y1 < y2  % the lower point is made the origin
    v = [x2 - x1, y2 - y1];
    theta = atan2(v(2),v(1));
else
    v = [x1 - x2, y1 - y2];
    theta = atan2(v(2),v(1));
end

% --- Executes on button press in Segment.
function Segment_Callback(hObject, eventdata, handles)
% hObject    handle to Segment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Publish.
function Publish_Callback(hObject, eventdata, handles)
% hObject    handle to Publish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
