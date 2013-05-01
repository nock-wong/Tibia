function spikes = detectSpikes(Q)
% Input "Q" array of coordinates of boundary
%   last element is the same as first. Size(Q,1)-1 gives the number
%   distinct points
% Output "spikes" listing spike points
% 
% Calculate metrics
N = size(Q,1)-1;
M = zeros(N,1);
for a = 1:N
    M(a,1) = distance(Q(a+1,:),Q(a,:));
end

spikes = zeros(N,1);
for a = 1:N
    if M(a) > 3*mean(M);
        spikes(a) = 1; 
    end
end
return    