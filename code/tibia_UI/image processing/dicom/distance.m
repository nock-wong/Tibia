function dist = distance(A,B)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
            v = A - B; %vector from point a to point a+1
            dist = norm(v);    %magnitude of vector
end

