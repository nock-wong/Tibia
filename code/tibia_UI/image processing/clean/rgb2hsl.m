%source: http://130.113.54.154/~monger/hsl-rgb.html
function [H S L] = rgb2hsl(rgb)
[maxColor maxI] = max(rgb);
[minColor minI] = min(rgb);

L = (maxColor + minColor)/2;

if maxColor == minColor
    H = 0;
    S = 0;
    return;
end

if L < .5
    S = (maxColor-minColor)/(maxColor+minColor);
end
if L >= .5
    S = (maxColor-minColor)/(2-maxColor-minColor);
end

R = rgb(1);
G = rgb(2);
B = rgb(3);
i = maxI;
if i == 1
    H = (G-B)/(maxColor-minColor);
end
if i == 2   
    H = 2 + (B-R)/(maxColor-minColor);
end
if i == 3
    H = 4 + (R-G)/(maxColor-minColor);
end


