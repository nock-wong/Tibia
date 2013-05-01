function varargout = gui(varargin)
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

% Last Modified by GUIDE v2.5 15-Feb-2012 03:00:00

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

n = size(images,1);
% Load raw axial view slides
axial = zeros(info.Columns, info.Rows, n, 'uint16');
axial(:,:,1) = dicomread(info);
for i = 2:size(images,1)
    info = dicominfo(char(images(i)));
    axial(:,:,i) = dicomread(info);
end
cd(dicomDir);

% Rescale the thickness so the volume grid is homogenous
thickness = info.SliceThickness;
pxSize = info.PixelSpacing(1);
l = floor((n-1) * thickness);
nPrime = floor(l/pxSize) + 1;
axialPrime = zeros(info.Columns, info.Rows, nPrime, 'uint16'); 
for m = 1:nPrime
    position = m*pxSize;
    low = floor(position);
    if low == 0
        low = 1;
    end
    high = ceil(position);
    if high > n
        high = n;
    end
    % linear interpolation between adjacent axial scans
    axialPrime(:,:,m) = axial(:,:,low)+(axial(:,:,high)-axial(:,:,low))*(position-low);
end

% % Generate coronal views
% coronal = zeros(nPrime,info.Rows,info.Columns,'uint16');
% for m = 1:nPrime
%    coronal(m,:,:) = (axialPrime(:,:,m))';
% end

% % Generate sagittal views
% sagittal = zeros(nPrime,info.Rows,info.Columns,'uint16');
% for m = 1:nPrime
%    sagittal(m,:,:) = axialPrime(:,:,m);
% end

axialBackUp = axial;
axial = axialPrime;

% Update properties of sliders based on range of CT scan
set(handles.slider_axial_pos,'Min',1);
set(handles.slider_axial_pos,'Max',size(axial,3));
set(handles.slider_axial_pos,'Value',round((1+size(axial,3))/2));
set(handles.slider_axial_pos,'SliderStep',[1/(size(axial,3)-1) 5/(size(axial,3)-1)]);

set(handles.slider_coronal_pos,'Min',1);
set(handles.slider_coronal_pos,'Max',size(axial,3));
set(handles.slider_coronal_pos,'Value',round((1+size(axial,3))/2));
set(handles.slider_coronal_pos,'SliderStep',[1/(size(axial,3)-1) 5/(size(axial,3)-1)]);

set(handles.slider_sagittal_pos,'Min',1);
set(handles.slider_sagittal_pos,'Max',size(axial,2));
set(handles.slider_sagittal_pos,'Value',round((1+size(axial,2))/2));
set(handles.slider_sagittal_pos,'SliderStep',[1/(size(axial,2)-1) 5/(size(axial,2)-1)]);

% Draw orientation lines
% handles.reformat_axial = imline(handles.plot_axial,double([(info.Columns)/2 0+50; (info.Columns)/2 (info.Rows)-50]));
handles.reformat_coronal = imline(handles.plot_coronal,double([(info.Columns)/2 0+50; (info.Columns)/2 size(axial,3)-50]));
handles.reformat_sagittal = imline(handles.plot_sagittal,double([(info.Columns)/2 0+50; (info.Columns)/2 size(axial,3)-50]));

% Save data
handles.axial_backup = axialBackUp;
handles.axial_data = axial;
% handles.coronal_data = coronal;
% handles.sagittal_data = sagittal;
handles.info_data = info;
guidata(hObject,handles);

% Plot
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

% --- Executes on slider movement.
function slider_axial_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_axial_pos,'Value'));    % ensure integer index
set(handles.slider_axial_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

% --- Executes on slider movement.
function slider_coronal_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_coronal_pos,'Value'));    % ensure integer index
set(handles.slider_coronal_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

% --- Executes on slider movement.
function slider_sagittal_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_sagittal_pos,'Value'));    % ensure integer index
set(handles.slider_sagittal_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

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
% Produce on-plane alignment vectors
apiCoronal = iptgetapi(handles.reformat_coronal);
pC = apiCoronal.getPosition();
vC = pC(2,:) - pC(1,:);

apiSagittal = iptgetapi(handles.reformat_sagittal);
pS = apiSagittal.getPosition();
vS = pS(2,:) - pS(1,:);

% Produce 3-D alignment vector
vA = [vS(2)/vC(1)*vC(1) vS(1) vS(2)];

% Calculate axis-angle from alignment to [0 0 1] in original frame
a = vA;
b = [0 0 1];
ax = cross(a,b)/norm(cross(a,b));
ang = atan2(norm(cross(a,b)),dot(a,b));

% Perform transformation
axial = handles.axial_data;
temp = zeros(519*519,2);
%temp(:,1) = reshape(repmat((1:519),519,1),519*519,1);
%temp(:,2) = repmat((1:519)',519,1);
for k = 1:1
    for i = 1:size(axial,1)
        for j = 1:size(axial,2)
            v = [i j k];
            vRot = v*cos(ang)+cross(ax,v)*sin(ang)+ax*dot(ax,v)*(1-cos(ang));
        end
    end
end

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

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function replotAxial(hObject, handles) 
set(gcf,'CurrentAxes',handles.plot_axial);
index = get(handles.slider_axial_pos,'Value');
set(handles.slider_axial_pos,'Value',index);
% api = iptgetapi(handles.reformat_axial);
% pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_axial_pos,'Max'));
imshow(handles.axial_data(:,:,index),[0,3071]);
line([0 1000], [get(handles.slider_coronal_pos,'Value') get(handles.slider_coronal_pos,'Value')],'Color','red');
line([get(handles.slider_sagittal_pos,'Value') get(handles.slider_sagittal_pos,'Value')],[0 1000],'Color','blue');
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
% handles.reformat_axial = imline(gca,pos);
guidata(hObject, handles);

function replotCoronal(hObject, handles)
set(gcf,'CurrentAxes',handles.plot_coronal);
index = get(handles.slider_coronal_pos,'Value');
api = iptgetapi(handles.reformat_coronal);
pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_coronal_pos,'Max'));
% imshow(handles.coronal_data(:,:,get(handles.slider_coronal_pos,'Value')),[0,3071]);
v = handles.axial_data(get(handles.slider_coronal_pos,'Value'),:,:);
v = permute(v,[3,2,1]);
imshow(v,[0,3071]);
line([0 1000], [get(handles.slider_axial_pos,'Value') get(handles.slider_axial_pos,'Value')],'Color','green');
line([get(handles.slider_sagittal_pos,'Value') get(handles.slider_sagittal_pos,'Value')],[0 1000],'Color','blue');
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_coronal = imline(gca,pos);
guidata(hObject, handles);

function replotSagittal(hObject, handles)
set(gcf,'CurrentAxes',handles.plot_sagittal);
index = get(handles.slider_sagittal_pos,'Value');
api = iptgetapi(handles.reformat_sagittal);
pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_sagittal_pos,'Max'));
% imshow(handles.sagittal_data(:,:,get(handles.slider_sagittal_pos,'Value')),[0,3071]);
v = handles.axial_data(:,get(handles.slider_sagittal_pos,'Value'),:);
v = permute(v,[3,1,2]);
imshow(v,[0,3071]);
line([0 1000], [get(handles.slider_axial_pos,'Value') get(handles.slider_axial_pos,'Value')],'Color','green');
line([get(handles.slider_coronal_pos,'Value') get(handles.slider_coronal_pos,'Value')], [0 1000],'Color','red');
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_sagittal = imline(gca,pos);
guidata(hObject, handles);
