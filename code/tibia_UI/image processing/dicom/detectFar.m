function spikes = detectFar(Q)
Input "Q" array of coordinates of boundary
  last element is the same as first. Size(Q,1)-1 gives the number
  distinct points
Output "spikes" listing spike points

Calculate metrics
N = size(Q,1)-1;
for a = 1:N
    V(a,:) = Q(a+1,:) - Q(a,:); %vector from point a to point a+1
    M(a) = norm(V(a));    %magnitude of vector
end
for a = 2:N
    A(a) = dot(V(a-1,:),V(a,:))/(M(a-1)*M(a));  %angle between vectors
end
A(1) = dot(V(N,:),V(2,:))/(M(N)*M(1));

spikes = zeros(N,1);
for a = 1:N
    if M(a) > 2*mean(M);
        spikes(a) = 1; 
    end
end
return    
