%If p is the probability of transferring from Good State to the bad state
%and if r is the probability of transferring from the bad state to the Good
%state, given the p and r values, this code will generate a packet loss
%pattern (with burst losses) and save it to a file named Loss_Pattern.txt.

clc
clear


file_names = ['or129'];
file_names = regexp(file_names,',','split');


for w=1:length(file_names)
    
    name = char(file_names(w));
     
    file_open = strcat('origFiles\', name, '.wav');
    info = audioinfo(file_open);
    
    if not(info.BitsPerSample == 16 )
        error(stringf('To use the G.191 PLC, audio files should be 16 bits per sample\nCurrently is: %d bits', info.BitsPerSample));
    
    elseif not(info.SampleRate == 8000)
        error(stringf('To use the G.191 PLC, auido files shoud be sampled at 8khz\n Currently is: %dkhz', info.SampleRate));
    end
   
    [x,fs] = audioread(file_open);
    x = x';
 
  
    
   % audiowrite('teste.wav',x2,fs);
              
    mean_MOS = zeros(4,8);
    frq_good  = zeros(4,8); % frequencia de pacotes bons
    sd_MOS = zeros(4,8);
 %   pr_value = zeros(4,8);
    p_value = zeros(4,8);
    r_value = zeros(4,8);
    
    total_packs = length(x);

        repeat = 100;
        
        for re = 1:repeat
            
            l = 1;
            
            for PLR = [1e-01, 1, 5, 10] %controla a quantidade de PRL(em porcentagem)

                c = 1;
                PLR = (PLR/100);

                for BurstR = [8, 7, 6, 5, 4, 3, 2, 1]
                                     
                   % pc = 1-(BurstR*(1-PLR));
                    
                   % r = 1- pc;
                    
                   % p = ((1-pc)*PLR)/(1-PLR);
                    
                    r = ((1-PLR)/BurstR); % r - > loss to found

                    check = 100;

                    p = (PLR/BurstR);
                    
                    
                    
                    while check >= 10

                    good = 0;
                    packets = [];

                    size_p = 1;

                    while size_p <= total_packs;

                    if good == 1
                        packets = [packets good];
                        good = rand(1) >  p;
                    elseif good == 0
                        packets = [packets good];
                        good = rand(1) > (1-r);
                    else
                        fprintf('error\n');
                        break;
                    end
                   
                    size_p = size_p + 1;
                    end
                    p_value(l,c) = p;
                    r_value(l,c) = r;
                   % pr_value(l,c) = (p/r);
                    frq_good(l,c) = frq_good(l,c)/(total_packs/2);

                    fid = fopen('Loss_Pattern.txt', 'wt');
                    fprintf(fid, '%d ', packets);
                    fclose(fid);
                    received_packs = nnz(packets);
                    theo_pack_loss_rate = 1 - r / (p+r);
                    act_pack_loss_rate = 1 - received_packs/total_packs;

                    check = abs(theo_pack_loss_rate - act_pack_loss_rate) / theo_pack_loss_rate * 100;

                    end


                      
                end
                    
                    result = x.*packets;
                    result2 = result';

                    file_name2 = strcat(name,'(PLR-', num2str(theo_pack_loss_rate), ';BurstR-', num2str(BurstR), ').wav' );
                    file_save = strcat('', file_name2);
                    audiowrite(file_save, result2, fs);
                    
                     
                    %PCL ALGORITHM
                    
                    %Nome do arquivo onde serão escritas os padroes de
                    %perda de pacote
                    file_lossPattern = strcat(file_name2,'-Loss_Pattern');                 
                    fid = fopen(strcat(file_lossPattern,'.txt'), 'wt');
                    fprintf(fid, '%d ', packets);
                    fclose(fid);
                
                     
                     %Envio o arquivo de lossPattern.txt e recebo
                     %lossPattern.g192
                    command5 = char(strcat('asc2g192.exe', {' '}, file_lossPattern ,'.txt',...
                    {' '}, file_lossPattern, '.g192'));
                    [~,cmdout] = system(command5);
                                                                               
                                          
                    %Aplico o algoritmo de PLC
                    command6 = char(strcat('g711iplc.exe',{' '},...
                    file_lossPattern,'.g192',...
                    {' '}, name,'(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ').wav', ...
                    {' '}, name, '(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ';PLC)'));                     
                    [~,cmdout] = system(command6);

                    
                    command = char(strcat('p862.exe', {' '}, file_open,...
                    {' '},name,'(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ';PLC)',' +', num2str(fs)));
                    [~,cmdout] = system(command);
                    pos = strfind(cmdout, 'PESQ_MOS');
                    MOS_valor1 = str2num(cmdout(pos+10:pos+15));
                    disp(sprintf('PESQ_MOS = %0.3f ',MOS_valor1));
                                  
                    mean_MOS(l,c) = mean_MOS(l,c) +  MOS_valor1;
                    sd_MOS(l,c) = sd_MOS(l,c) + MOS_valor1.^2;
                    c = c +1;
                    
                    fid = fopen('Result_MOS.txt');
                    fprintf(strcat(' \n', name));
             
                    
                    dlmwrite('Result_MOS.txt', mean_MOS, 'delimiter', ' ');
                    
                    
                    fprintf(' \n\n');
                    fclose(fid);
                    
                    fid = fopen(strcat(file_save,'-Loss_Pattern.txt'), 'wt');
                    fprintf(fid, '%d ', packets);
                    fclose(fid);
                
            end
              
                
                l = l+1;
        end

end
        
    for i = 1:size(mean_MOS,1) 
        
        for j = 1:size(mean_MOS,2)
            mean_MOS(i,j) = mean_MOS(i,j)/repeat;
           % frq_good(i,j) = (frq_good(i,j)/total_packs);
            sd_MOS(i,j) = sqrt((sd_MOS(i,j) - (repeat*mean_MOS(i,j).^2))/(repeat-1));
            
        end
        
    end
    
packets
theo_pack_loss_rate = p / (p+r);
act_pack_loss_rate = 1 - received_packs/total_packs;


