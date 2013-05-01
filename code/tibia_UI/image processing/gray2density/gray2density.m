clc;
clear all;

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
sampleRGB = imread('gray.jpg');
outputRGB = sampleRGB;
sampleGV = rgb2gray(sampleRGB);
figure(1);
imshow(sampleGV);
edge = edge(sampleGV,'roberts');
figure(2);
imshow(edge);
density = 114+.916*double(sampleGV)/255*2674;

level = round((density - 950)/200)+1;
for m = 1:size(density,1)
    for n = 1:size(density,2)
        if level(m,n) >= 1 
            outputRGB(m,n,:) = legendRGB(level(m,n),:);
        end
        if level(m,n) < 0
            outputRGB(m,n,:) = [255 255 255];
        end
    end
end
figure(3);
imshow(outputRGB);