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

% Last Modified by GUIDE v2.5 17-Feb-2012 23:28:25

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

function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
clc;
addpath(genpath(pwd));

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

axialBackUp = axial;
axial = axialPrime;

% Save data
handles.axial_backup = axialBackUp;
handles.axial_data = axial;
handles.info_data = info;
guidata(hObject,handles);

% Update sliders and lines
update(hObject,guidata(hObject));
% Plot
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

function slider_axial_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_axial_pos,'Value'));    % ensure integer index
set(handles.slider_axial_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

function slider_coronal_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_coronal_pos,'Value'));    % ensure integer index
set(handles.slider_coronal_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

function slider_sagittal_pos_Callback(hObject, eventdata, handles)
index = round(get(handles.slider_sagittal_pos,'Value'));    % ensure integer index
set(handles.slider_sagittal_pos,'Value',index);
guidata(hObject,handles);
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

function Reformat_Callback(hObject, eventdata, handles)
fprintf('Reformatting...\n');
tic;
% Produce on-plane alignment vectors
apiCoronal = iptgetapi(handles.reformat_coronal);
pC = apiCoronal.getPosition();
vC = pC(2,:) - pC(1,:);
apiSagittal = iptgetapi(handles.reformat_sagittal);
pS = apiSagittal.getPosition();
vS = pS(2,:) - pS(1,:);
% Produce 3-D alignment vector
vA = [vS(1) vS(2)/vC(2)*vC(1) vS(2)];
% Calculate axis-angle from alignment to [0 0 1] in original frame
a = vA;
b = [0 0 1];
if(isequal(abs(a),b))
    return
end
ax = -cross(a,b)/norm(cross(a,b));
ang = atan2(norm(cross(a,b)),dot(a,b));
% Perform transformation
axial = handles.axial_data;
axSize = size(axial);
newAxial = uint16(zeros(axSize(1),axSize(2),axSize(3)));

v = zeros(axSize(1)*axSize(2),3);
u = repmat(ax,axSize(1)*axSize(2),1);
vRot = zeros(axSize(1)*axSize(2),3);
GROT = uint16(zeros(axSize(1)*axSize(2),1));
% Populate with indices of slide
v(:,2) = repmat((1:axSize(2))',axSize(1),1);
v(:,1) = reshape(repmat(1:axSize(1),axSize(1),1),axSize(1)*axSize(1),1);
for k = 1:axSize(3)
    v(:,3) = repmat(k,axSize(1)*axSize(2),1);
    % Translation vector
    c = axSize/2;
    cRot = cos(ang)*c+...
        sin(ang)*cross(ax,c,2)+...
        (1-cos(ang))*ax*dot(ax,c);
    % Calculate pixel-to-pixel rotation map
    vRot = cos(ang)*v+...
        sin(ang)*cross(u,v,2)+...
        (1-cos(ang))*u.*repmat(dot(u,v,2),1,3)+...
        +repmat(c-cRot,axSize(1)*axSize(2),1);
    % Perform mapping of grayvalues
    M = vRot(:,1)>2 & vRot(:,1)<size(axial,1) &...
        vRot(:,2)>2 & vRot(:,2)<size(axial,2) &...
        vRot(:,3)>2 & vRot(:,3)<size(axial,3);
    
    X = vRot(M,1);
    Y = vRot(M,2);
    Z = vRot(M,3);
    
    %     % Nearest neighbor method
    %     ZI = uint32((round(Z)-1)*axSize(1)*axSize(2));
    %     YI = uint32((round(Y)-1)*axSize(1));
    %     XI = uint32((round(X)-1));
    %     GROT(M) = axial(ZI+YI+XI);
    %     newAxial(:,:,k) = reshape(GROT,[size(axial,1),size(axial,2)])';
    %     GROT = uint16(zeros(axSize(1)*axSize(2),1));
    
    % Trilinear interpolation method
    XHI = ceil(X);
    XLO = floor(X);
    YHI = ceil(Y);
    YLO = floor(Y);
    ZHI = ceil(Z);
    ZLO = floor(Z);
    DX = X-XLO;
    DY = Y-YLO;
    DZ = Z-ZLO;
    D = horzcat((1-DX) .* (1-DY) .* (1-DZ),...
        (1-DX) .* (1-DY) .* (DZ),...
        (1-DX) .* (DY) .* (1-DZ),...
        (1-DX) .* (DY) .* (DZ),...
        (DX) .* (1-DY) .* (1-DZ),...
        (DX) .* (DY) .* (1-DZ),...
        (DX) .* (1-DY) .* (DZ),...
        (DX) .* (DY) .* (DZ));
    ZLOI = uint32((ZLO-1)*axSize(1)*axSize(2));
    ZHII = uint32((ZHI-1)*axSize(1)*axSize(2));
    YLOI = uint32((YLO-1)*axSize(1));
    YHII = uint32((YHI-1)*axSize(1));
    XLOI = uint32((XLO-1));
    XHII = uint32((XHI-1));
    G = horzcat(axial(XLOI+YLOI+ZLOI),...
        axial(XLOI+YLOI+ZHII),...
        axial(XLOI+YHII+ZLOI),...
        axial(XLOI+YHII+ZHII),...
        axial(XHII+YLOI+ZLOI),...
        axial(XHII+YHII+ZLOI),...
        axial(XHII+YLOI+ZHII),...
        axial(XHII+YHII+ZHII));
    GD = uint16(sum(D.*double(G),2));
    GROT(M) = GD;
    newAxial(:,:,k) = reshape(GROT,[size(axial,1),size(axial,2)])';
    GROT = uint16(zeros(axSize(1)*axSize(2),1));
end

fprintf('Reformatting completed in %f seconds\n',toc);
handles.axial_data = newAxial;
guidata(hObject,handles);
update(hObject,guidata(hObject));
replotAxial(hObject,guidata(hObject));
replotCoronal(hObject,guidata(hObject));
replotSagittal(hObject,guidata(hObject));

function segment_Callback(hObject, eventdata, handles)

function replotAxial(hObject, handles)
set(gcf,'CurrentAxes',handles.plot_axial);
index = get(handles.slider_axial_pos,'Value');
set(handles.slider_axial_pos,'Value',index);
api = iptgetapi(handles.reformat_axial);
pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_axial_pos,'Max'));
imshow(handles.axial_data(:,:,index),[0,3071]);
line([0 1000], [get(handles.slider_coronal_pos,'Value') get(handles.slider_coronal_pos,'Value')],'Color',[0.93 0.84 0.84]);
line([get(handles.slider_sagittal_pos,'Value') get(handles.slider_sagittal_pos,'Value')],[0 1000],'Color',[0.73 0.83 0.96]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_axial = imline(gca,pos);
guidata(hObject, handles);

function replotCoronal(hObject, handles)
set(gcf,'CurrentAxes',handles.plot_coronal);
index = get(handles.slider_coronal_pos,'Value');
api = iptgetapi(handles.reformat_coronal);
pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_coronal_pos,'Max'));
v = handles.axial_data(get(handles.slider_coronal_pos,'Value'),:,:);
v = permute(v,[3,2,1]);
imshow(v,[0,3071]);
line([0 1000], [get(handles.slider_axial_pos,'Value') get(handles.slider_axial_pos,'Value')],'Color',[.75 .87 .78]);
line([get(handles.slider_sagittal_pos,'Value') get(handles.slider_sagittal_pos,'Value')],[0 1000],'Color',[0.73 0.83 0.96]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_coronal = imline(gca,pos);
guidata(hObject, handles);

function replotSagittal(hObject, handles)
set(gcf,'CurrentAxes',handles.plot_sagittal);
index = get(handles.slider_sagittal_pos,'Value');
api = iptgetapi(handles.reformat_sagittal);
pos = api.getPosition();
label = sprintf('%d:%d',index,get(handles.slider_sagittal_pos,'Max'));
v = handles.axial_data(:,get(handles.slider_sagittal_pos,'Value'),:);
v = permute(v,[3,1,2]);
imshow(v,[0,3071]);
line([0 1000], [get(handles.slider_axial_pos,'Value') get(handles.slider_axial_pos,'Value')],'Color',[.75 .87 .78]);
line([get(handles.slider_coronal_pos,'Value') get(handles.slider_coronal_pos,'Value')], [0 1000],'Color',[0.93 0.84 0.84]);
text(0,0,label,'VerticalAlignment','top','Color','r','FontSize',16);
handles.reformat_sagittal = imline(gca,pos);
guidata(hObject, handles);

function update(hObject, handles)

axial = handles.axial_data;

% Update properties of sliders based on range of CT scan
set(handles.slider_axial_pos,'Min',1);
set(handles.slider_axial_pos,'Max',size(axial,3));
set(handles.slider_axial_pos,'Value',round((1+size(axial,3))/2));
set(handles.slider_axial_pos,'SliderStep',[1/(size(axial,3)-1) 5/(size(axial,3)-1)]);

set(handles.slider_coronal_pos,'Min',1);
set(handles.slider_coronal_pos,'Max',size(axial,1));
set(handles.slider_coronal_pos,'Value',round((1+size(axial,1))/2));
set(handles.slider_coronal_pos,'SliderStep',[1/(size(axial,1)-1) 5/(size(axial,1)-1)]);

set(handles.slider_sagittal_pos,'Min',1);
set(handles.slider_sagittal_pos,'Max',size(axial,2));
set(handles.slider_sagittal_pos,'Value',round((1+size(axial,2))/2));
set(handles.slider_sagittal_pos,'SliderStep',[1/(size(axial,2)-1) 5/(size(axial,2)-1)]);

% Draw orientation lines
handles.reformat_axial = imline(handles.plot_coronal,double([size(axial,2)/2 0+50; size(axial,1)/2 size(axial,3)-50]));
handles.reformat_coronal = imline(handles.plot_coronal,double([size(axial,2)/2 0+50; size(axial,2)/2 size(axial,3)-50]));
handles.reformat_sagittal = imline(handles.plot_sagittal,double([size(axial,1)/2 0+50; size(axial,1)/2 size(axial,3)-50]));

guidata(hObject,handles);

function slider_axial_pos_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_coronal_pos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_coronal_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_sagittal_pos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_sagittal_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function varargout = gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;