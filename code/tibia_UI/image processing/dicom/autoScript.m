clear all;
clc;

SHOWOUTPUT = 1;
SHOWHU = 0;

%Legend
legendRGB = uint8([  0   0 193
    0  42 255
    0 241 255
    0 218  71
    127 229   0
    255 213   0
    255  97   0
    255  0    0
    193  0    0
    153  0    0]);
%Import dicom file
info = dicominfo('67283520');
%Note: GV = HU + 1024;
GV = dicomread(info);

if SHOWHU;
    huFigure = figure('Name','Hu');
    imshow(GV);
    imcontrast;
end

nodes = defineBoundary(GV,info);
spacing = getfield(info,'PixelSpacing');
tibiaMask = poly2mask(nodes(:,1),nodes(:,2),size(GV,1),size(GV,2));


perimeter = 0;
for a = 1:size(nodes,1)-1
    vectors(a,:) = nodes(a+1,:)-nodes(a,:);
    perimeter = perimeter + norm(vectors(a,:))*spacing(1);
end

area = 0;
for a = 1:size(nodes,1)-1
    area = area + (nodes(a,1)*nodes(a+1,2)-nodes(a,2)*nodes(a+1,1));
end
area = abs(area)/2*spacing(1)^2;

compactness = perimeter^2/area;

tibiaMask = poly2mask(nodes(:,1),nodes(:,2),size(GV,1),size(GV,2));

%Calculate density
density = 114+.916*double(GV);
%Discretize density
blocks = size(legendRGB,1);
range = 2000 - 300;
increment = range/blocks;
level = uint8(round((density - 950)/200)+1);
maskedLevel = uint8(tibiaMask) .* level;
outputRGB = zeros(size(density,1),size(density,2),3);
%Plot
for m = 1:size(density,1)
    for n = 1:size(density,2)
        if maskedLevel(m,n) >= 1
            if maskedLevel(m,n) > 10
                maskedLevel(m,n) = 10;
            end
            outputRGB(m,n,:) = legendRGB(maskedLevel(m,n),:);
        end
        if maskedLevel(m,n) <= 0
            outputRGB(m,n,:) = [255 255 255];
        end
    end
end

%Scale gray value
filterscaleGV = uint8(tibiaMask).*uint8(double(GV)/double(max(max(GV)))*255);

if SHOWOUTPUT
    outputFigure = figure('Name','Output');
    hold on;
    imshow(outputRGB); 
    patientID = getfield(info,'PatientID');
    study = getfield(info,'StudyID');
    series = getfield(info,'SeriesDescription');
    gender = getfield(info,'PatientSex');
    date = getfield(info,'AcquisitionDate');
    areaText = sprintf('Area: %4.2f mm^2',area);
    perimeterText = sprintf('Perimeter: %3.2f mm',perimeter);
    compactnessText = sprintf('Compactness: %2.1f',compactness);
    textBox = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',patientID,study,gender,series,date,areaText,perimeterText,compactnessText);
    text(0,0,textBox,'VerticalAlignment','top');
    print(gcf,'-djpeg','-r300','output');
    close all;
end
