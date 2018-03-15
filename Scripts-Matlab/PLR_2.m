%If p is the probability of transferring from Good State to the bad state
%and if r is the probability of transferring from the bad state to the Good
%state, given the p and r values, this code will generate a packet loss
%pattern (with burst losses) and save it to a file named Loss_Pattern.txt.

clc
clear


file_names = ['m_25_en_c_se01,Orig8k'];
file_names = regexp(file_names,',','split');


for w=1:length(file_names)
    
    name = char(file_names(w));
      
    file_open = strcat('origFiles\', name, '.wav');
    
    [x,fs] = audioread(file_open);
    x2 = x';


    total_packs = length(x2);


    for PLR = [1e-01, 1, 5, 10] %controla a quantidade de PRL(em porcentagem)

        PLR = (PLR/100);

        for i = 1:5 %controla quatro difentes distribuições para cada PRL
        if i == 1
            r = 0.35;

        elseif i == 2
            r = 0.25;

        elseif i == 3
            r = 0.18;

        elseif i == 4
            r = 0.10;

        elseif i == 5
            r = 0.05;
        end

        check = 100;
        p = (PLR*r)/(1-PLR); % PLR = P/P+R, mantem constante o valor de PLR, obtenho o valor de p

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

        fid = fopen('Loss_Pattern.txt', 'wt');
        fprintf(fid, '%d ', packets);
        fclose(fid);
        received_packs = nnz(packets);
        theo_pack_loss_rate = 1 - r / (p+r);
        act_pack_loss_rate = 1 - received_packs/total_packs;

        check = abs(theo_pack_loss_rate - act_pack_loss_rate) / theo_pack_loss_rate * 100;

        end

        result = x2 .* packets;
        result2 = result';

        file_save = strcat('degFiles\', name,'( PLR-', num2str(theo_pack_loss_rate), ' r-', num2str(r), ').wav' );

        audiowrite(file_save, result2, fs);

        end

        continue
    end
end
packets
theo_pack_loss_rate = p / (p+r);
act_pack_loss_rate = 1 - received_packs/total_packs;


