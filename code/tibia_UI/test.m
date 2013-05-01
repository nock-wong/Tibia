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

% Rescale the volume so grid is homogenous
thickness = info.SliceThickness;
pxSize = info.PixelSpacing(1);
l = (n-1) * thickness;
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
