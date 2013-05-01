function nodes = traceTibia(GV,info)

%Boundary detection parameters
N = 145;
steps = 100;
resolution = 1;

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
nodeCount = size(nodes,1)-1;
for t = 1:steps;
    for a = 1:nodeCount
        vector = center - nodes(a,:);
        direction = vector/norm(vector);
        boneMask(uint16(nodes(a,1)),uint16(nodes(a,2)));
        if boneMask(uint16(nodes(a,2)),uint16(nodes(a,1)))~= 1
            nodes(a,:) = nodes(a,:) + resolution*direction;
        end
    end
    nodes(N+1,:) = nodes(1,:);
end

for p = 1:4
    [spikes] = detectSpikes(nodes);
    nodes = smoothSpikes(nodes,spikes);
end
return