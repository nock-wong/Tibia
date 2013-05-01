clc;
clear all;
clf;
close all;

SHOWHU = 0;
SHOWBONEMASK = 1;
DEBUGAPPROACH = 0;
DEBUGSPIKE = 1;
SHOWBOUNDARY = 1;
SHOWOUTPUT = 1;

%Boundary detection parameters
N = 128 ;
steps = 100;
resolution = 1;
closeness = .27;

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
info = dicominfo('67283496');
%Note: GV = HU + 1024;
GV = dicomread(info);
if SHOWHU;
    huFigure = figure('Name','Hu');
    imshow(GV);
    imcontrast;
end

%Preliminary isolation of bone by thresholding
%D1 (hard cortical) type: 1200 and above
threshMin = 1200;
threshMax = 2000;
boneMask = uint8(zeros(size(GV,1),size(GV,2)));
for m = 1:size(GV,1)
    for n =1:size(GV,2)
        if GV(m,n) < threshMin || GV(m,n) > threshMax;
            boneMask(m,n) = 0;
        else
            boneMask(m,n) = 1;
        end
    end
end;
if SHOWBONEMASK
    bonemaskFigure = figure('Name','Threshold Mask');
    imshow(logical(boneMask));
    hold on;
end

%Boundary detection
%Populate nodes
spacing = getfield(info,'PixelSpacing');
radius = 55/spacing(1);
center = [size(boneMask,1)/2 size(boneMask,2)/2];
inc = 360/N;
deg = 0;
nodes = zeros(N+1,2);
seperation = zeros(N,1);
for a = 1:N
    x = center(1) + radius*cosd(deg);
    y = center(2) + radius*sind(deg);
    nodes(a,:) = [x y];
    deg = deg + inc;
end
nodes(N+1,:) = [center(1)+radius center(2)];

%Approach part
for t = 1:steps;
    if DEBUGAPPROACH
        plot(center(1),center(2),'g+','MarkerSize',5);
        figure(bonemaskFigure);
        plot(nodes(:,1),nodes(:,2),'ro-','MarkerSize',2);
        pause;
    end
    for a = 1:N
        vector = center - nodes(a,:);
        direction = vector/norm(vector);
        boneMask(uint16(nodes(a,1)),uint16(nodes(a,2)));
        if boneMask(uint16(nodes(a,2)),uint16(nodes(a,1)))~= 1
            nodes(a,:) = nodes(a,:) + resolution*direction;
        end
    end
    nodes(N+1,:) = nodes(1,:);
end

if DEBUGAPPROACH
    plot(center(1),center(2),'g+','MarkerSize',5);
    figure(bonemaskFigure);
    plot(nodes(:,1),nodes(:,2),'ro-','MarkerSize',2);
end

%Spike removal
for a = 1:N
    vectors(a,:) = nodes(a+1,:)-nodes(a,:);
end
for a = 1:N-1
    angles(a) = dot(vectors(a+1,:),vectors(a,:))/(norm(vectors(a+1,:))*norm(vectors(a,:)));
end
angles(N) = dot(vectors(1,:),vectors(N,:))/(norm(vectors(1,:))*norm(vectors(N,:)));
for a = 1:N-1
    seperation(a) = abs(angles(a+1)-angles(a));
end
seperation(N) = abs(angles(1) - angles(N));
for a = 1:N
    if seperation(a) > closeness
        if a == 1
            if seperation(N) > closeness
                if DEBUGSPIKE
                    figure(bonemaskFigure);
                    plot(nodes(a,1),nodes(a,2),'g+','MarkerSize',2);
                end
                nodes(1,:) = nodes(N,:);
                nodes(N+1,:) = nodes(1,:);
            end
        else
            if seperation(a-1) > closeness
                if DEBUGSPIKE
                    figure(bonemaskFigure);
                    plot(nodes(a,1),nodes(a,2),'g+','MarkerSize',2);
                end
                nodes(a,:) = nodes(a-1,:);
            end
        end
    end
end

%Remove redundant nodes
a = 1;
while a < size(nodes,1)
    if nodes(a,:) == nodes(a+1,:)
        if a == 1
            nodes(1,:) = [];
            nodes(end,:) = nodes(1,:);
        else
            nodes(a,:) = [];
        end
    else
        a = a+1;
    end
end

if SHOWBOUNDARY
    boundaryFigure = figure('Name','Boundary');
    imshow(logical(boneMask));
    hold on;
    plot(nodes(:,1),nodes(:,2),'r.-','MarkerSize',2);
    print(gcf,'-djpeg','-r300','boundary');
end

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

if SHOWOUTPUT
    outputFigure = figure('Name','Output');
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
end