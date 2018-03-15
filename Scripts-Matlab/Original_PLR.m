%If p is the probability of transferring from Good State to the bad state
%and if r is the probability of transferring from the bad state to the Good
%state, given the p and r values, this code will generate a packet loss
%pattern (with burst losses) and save it to a file named Loss_Pattern.txt.

clc

p = 0.02777;
r = 0.25;

total_packs = 10000;


check = 100;

while check >= 10

good = 1;
packets = [];

size = 1;

    while size <= total_packs
    if good == 1
        packets = [packets good];
        good = rand(1) > p;
    elseif good == 0
        packets = [packets good];
        good = rand(1) > (1-r);
    else
        fprintf('error\n');
        break;
    end
    size = size + 1;
    end

fid = fopen('Loss_Pattern.txt','w');
fprintf(fid, '%d ', packets);
fclose(fid);
received_packs = nnz(packets);
theo_pack_loss_rate = 1 - r / (p+r);
act_pack_loss_rate = 1 - received_packs/total_packs;

check = abs(theo_pack_loss_rate - act_pack_loss_rate) / theo_pack_loss_rate * 100;

end


packets
theo_pack_loss_rate = p / (p+r)
act_pack_loss_rate = 1 - received_packs/total_packs