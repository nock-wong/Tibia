clc;
clear all;

f = 1;
SHOWHU = 0;
SHOWBONEMASK = 0;
    DEBUGAPPROACH = 0;
N = 128 ;
steps = 100;
resolution = 1;
closeness = .3;

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
info = dicominfo('67283495');
HU = dicomread(info);
if SHOWHU;
    huFigure = figure('Name','Hu');
    imshow(HU);
    imcontrast;
end

%Preliminary isolation of bone by thresholding
%D1 (hard cortical) type: 1200 and above
threshMin = 1200;
threshMax = 2000;
boneMask = uint8(zeros(size(HU,1),size(HU,2)));
for m = 1:size(HU,1)
    for n =1:size(HU,2)
        if HU(m,n) < threshMin || HU(m,n) > threshMax;
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
    %seperation(a) = norm(nodes(a,:)-nodes(a+1,:));
    seperation(a) = abs(angles(a+1)-angles(a));
end
seperation(N) = abs(angles(1) - angles(N));
for a = 1:N
    if seperation(a) > closeness
        if a == 1
            if seperation(N) > closeness
                %figure(1);
                %plot(nodes(a,1),nodes(a,2),'g+','MarkerSize',2);
                %nodes(1,:) = (nodes(N,:)+nodes(2,:))/2;
                nodes(1,:) = nodes(N,:);
                nodes(N+1,:) = nodes(1,:);
            end
        else
            if seperation(a-1) > closeness
                %figure(1);
                %plot(nodes(a,1),nodes(a,2),'g+','MarkerSize',2);
                %nodes(a,:) = (nodes(a-1,:)+nodes(a+1,:))/2;
                nodes(a,:) = nodes(a-1,:);
            end
        end
    end
end
figure(f);
f = f +1;
imshow(logical(boneMask));
hold on;
plot(nodes(:,1),nodes(:,2),'r.-','MarkerSize',2);

perimeter = 0;
for a = 1:N
    vectors(a,:) = nodes(a+1,:)-nodes(a,:);
    perimeter = perimeter + norm(vectors(a,:));
end

area = 0;
for a = 1:N
    area = area + (nodes(a,1)*nodes(a+1,2)-nodes(a,2)*nodes(a+1,1));
end
area = abs(area)/2;

tibiaMask = poly2mask(nodes(:,1),nodes(:,2),size(HU,1),size(HU,2));
figure(f);
f = f +1;
huMask = uint16(tibiaMask) .* HU;
imshow(huMask);
imcontrast;
hold on;



% maskedHU = uint16(boneMask) .* HU;
% imshow(maskedHU);
% imcontrast;
% %calculate density
% GV = HU + 1024;
% density = 114+.916*double(GV);
% %section into blocks
% blocks = size(legendRGB,1);
% range = 2000 - 400;
% increment = range/blocks;
% level = uint8(round((density - 1500)/increment)+1);
% maskedLevel = boneMask .* level;
% %plot
% for m = 1:size(density,1)
%     for n = 1:size(density,2)
%             if maskedLevel(m,n) >= 1
%                 if maskedLevel(m,n) > 10
%                     maskedLevel(m,n) = 10;
%                 end
%                 outputRGB(m,n,:) = legendRGB(level(m,n),:);
%             end
%             if maskedLevel(m,n) <= 0
%                 outputRGB(m,n,:) = [255 255 255];
%             end
%     end
% end
% figure(2);
% imshow(outputRGB);