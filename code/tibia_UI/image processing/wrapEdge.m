%rubber band model for edge-detection

function wrapEdge(N)
clc;
clear all;
clf;

N = 79;
steps = 500;
k = 1;
deltaT = .1;

figure(1);

bodyImage = imread('gray.jpg');
%imshow(bodyImage);
hold on;
axis equal;
axis off;
window = [size(bodyImage,2) size(bodyImage,1)];
radius = min(window)/2-1;
center = [window(1)/2 window(2)/2];
%plot(center(1),center(2),'k+','MarkerSize',5);
%populate nodes
inc = 360/N;
deg = 0;
nodes = zeros(N+1,2);
for a = 1:N
    x = center(1) + radius*cosd(deg);
    y = center(2) + radius*sind(deg);
    nodes(a,:) = [x y];
    deg = deg + inc;
end
nodes(N+1,:) = [center(1)+radius center(2)];
links = zeros(N,2);
lengths = zeros(N,1);
directions = zeros(N,2);
forces = zeros(N,2);
velocities = zeros(N,2);
for i = 1:steps
    plot(nodes(:,1),nodes(:,2),'r*-','MarkerSize',1);
%     A(i) = getframe;
    %vector between adjacent nodes
    for a = 1:N
        links(a,:) = nodes(a+1,:)-nodes(a,:);
        lengths(a) = norm(links(a,:));
        directions(a,:) = links(a,:)/lengths(a);
    end
    for a = 1:N
        if a == 1
            forceX = (-k*lengths(a)*directions(N,1) + k*lengths(a)*directions(2,1));
            forceY = (-k*lengths(a)*directions(N,2) + k*lengths(a)*directions(2,2));
        elseif a == N
            forceX = (-k*lengths(a)*directions(a-1,1) + k*lengths(a)*directions(1,1));
            forceY = (-k*lengths(a)*directions(a-1,2) + k*lengths(a)*directions(1,2));
        else
            forceX = (-k*lengths(a)*directions(a-1,1) + k*lengths(a)*directions(a+1,1));
            forceY = (-k*lengths(a)*directions(a-1,2) + k*lengths(a)*directions(a+1,2));
        end
        nodes(a,:) = nodes(a,:) +  velocities(a,:)*deltaT + 1/2*[forceX forceY]*deltaT^2;
        velocities(a,:) = velocities(a,:) + [forceX forceY]*deltaT;
    end
    nodes(N+1,:) = nodes(1,:);
end
% filename = sprintf('%d.avi',N);
% cd shots;
% movie2avi(A,filename,'compression','none');
% cd ..;