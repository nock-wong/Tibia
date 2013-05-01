function nodes = smoothSpikes(Q,spikes)
for a = 1:size(Q,1)-1
    if spikes(a) == 1
        long = distance(Q(a,:),Q(a+1,:));
        for b = a+1:size(Q,1)-1
            short = distance(Q(a,:),Q(b,:));
            if short < long
                for c = a+1:b-1
                    Q(c,:) = Q(b,:);
                end
                break
            end
        end
    end
end
nodes = Q;

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
return

