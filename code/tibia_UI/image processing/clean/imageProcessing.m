clc;
clear all;

sample = imread('sampleAxial.png');
legendRGB = [  0   0 193
    0  42 255
    0 241 255
    0 218  71
    127 229   0
    255 213   0
    255  97   0
    255  0    0
    193  0    0
    153  0    0];

%convert to 0-1 RGB
sample = double(sample)/255;
sampleR = sample(:,:,1);
sampleG = sample(:,:,2);
sampleB = sample(:,:,3);
legendRGB = double(legendRGB)/255;

%convert legend to HSL
legendHSL = double(legendRGB);
for a = 1:size(legendRGB,1)
    [legendHSL(a,1) legendHSL(a,2) legendHSL(a,3)] = rgb2hsl(legendRGB(a,:));
end

output = sample;

for m = 1:size(sample,1)
    for n = 1:size(sample,2)
        if sample(m,n,1) ~= 0 &&...
                sample(m,n,2) ~= 0 &&...
                sample(m,n,3) ~= 0
            distSmall = 3*255^2+1;
            aSmall = -1;
            for a = 1:size(legendRGB,1)
                [HSL(1) HSL(2) HSL(3)] = rgb2hsl(sample(m,n,:));
                A = .5;
                B = .5;
                C = 1;
                dist = A*(HSL(1) - legendHSL(a,1))^2+...
                    B*(HSL(2) - legendHSL(a,2))^2+...
                    C*(HSL(3) - legendHSL(a,3))^2;
                %             dist = (sample(m,n,1)-legendRGB(a,1))^2+...
                %                 (sample(m,n,2)-legendRGB(a,2))^2+...
                %                 (sample(m,n,3)-legendRGB(a,3))^2;
                if dist <= distSmall
                    distSmall = dist;
                    aSmall = a;
                end
            end
            output(m,n,1:3) = legendRGB(aSmall,:);
        end
    end
end

figure(2);
imshow(output);
