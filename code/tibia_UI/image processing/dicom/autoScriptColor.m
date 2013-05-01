clear all;
clc;

SHOWOUTPUT = 1;
SHOWHU = 0;

%Import dicom file
info = dicominfo('67283495');
%Note: GV = HU + 1024;
GV = dicomread(info);
pause;
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
density = tibiaMask .* density/max(density(:));

if SHOWOUTPUT
    outputFigure = figure('Name','Output');
    hold on;
    imshow(density);
    colormap jet;
    patientID = getfield(info,'PatientID');
    study = getfield(info,'StudyID');
    series = getfield(info,'SeriesDescription');
    gender = getfield(info,'PatientSex');
    date = getfield(info,'AcquisitionDate');
    areaText = sprintf('Area: %4.2f mm^2',area);
    perimeterText = sprintf('Perimeter: %3.2f mm',perimeter);
    compactnessText = sprintf('Compactness: %2.1f',compactness);
    textBox = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',patientID,study,gender,series,date,areaText,perimeterText,compactnessText);
    text(0,0,textBox,'VerticalAlignment','top','Color','white');
    print(gcf,'-djpeg','-r300','output');
    close all;
end