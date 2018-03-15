%If p is the probability of transferring from Good State to the bad state
%and if r is the probability of transferring from the bad state to the Good
%state, given the p and r values, this code will generate a packet loss
%pattern (with burst losses) and save it to a file named Loss_Pattern.txt.

clc
clear


file_names = ['Sample1_16bit'];
file_names = regexp(file_names,',','split');


for w=1:length(file_names)
    
    name = char(file_names(w));    
    file_open = strcat('origFiles\', name, '.wav');
    [orig,fs] =  audioread(file_open); % apenas para obter fs
    
    % PCM - ENCODE
    
    law = 'A'; %aceita A ou u
    convertion = 'lili'; %lili, lilo ou loli
    pcm_encode = strcat(name, '.pcm'); % output do g711
    block_size = 256; % tamanho do bloco em amostras, default é 256
    first_block = 1; % primeiro bloco do input a ser processado, default é 1
    numb_blocks = 0; % numero de blocos que serao processados, default é end of file (0)
    
    if(numb_blocks == 0)        
        command1 = char(strcat('g711demo.exe', {' '}, law ,{' '},num2str(convertion),...
        {' '},name,'.wav', {' '}, pcm_encode, {' '}, num2str(block_size), {' '}, num2str(first_block)));
        [~,cmdout] = system(command1);

    else
        command2 = char(strcat('g711demo.exe', {' '}, law ,{' '},num2str(convertion),...
        {' '},name,'.wav', {' '}, pcm_encode, {' '}, num2str(block_size), {' '},...
        num2str(first_block), {' '}, num2str(numb_blocks)));
        [~,cmdout] = system(command2);
        
    end
    
    fid=fopen(pcm_encode,'r');
    audio_encoded = fread(fid,inf,'int16');
    fclose(fid);         

    x = audio_encoded';
    
    mean_MOS = zeros(4,8);
    frq_good  = zeros(4,8); % frequencia de pacotes bons
    sd_MOS = zeros(4,8);
   % pr_value = zeros(4,8);
   % p_value = zeros(4,8);
   % r_value = zeros(4,8);
    
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
                   % p_value(l,c) = p;
                   % r_value(l,c) = r;
                   % pr_value(l,c) = (p/r);
                    frq_good(l,c) = frq_good(l,c)/(total_packs/2);

                    fid = fopen('Loss_Pattern.txt', 'wt');
                    fprintf(fid, '%d ', not(packets));
                    fclose(fid);
                    received_packs = nnz(packets);
                    theo_pack_loss_rate = 1 - r / (p+r);
                    act_pack_loss_rate = 1 - received_packs/total_packs;

                    check = abs(theo_pack_loss_rate - act_pack_loss_rate) / theo_pack_loss_rate * 100;

                    end

                    result = x .* packets; %result e o vetor com degradacoes
                    
                    fileID = fopen(pcm_encode,'w');
                    fwrite(fileID,result,'int16');
                    fclose(fileID);
                   
                    %audiowrite(pcm_encode,result);
                 
                    %PCM DECODE
                   
                    pcm_decode = strcat(name,'(PLR-', num2str(theo_pack_loss_rate), ';BurstR-', num2str(BurstR),';PLC)'); %pcm decoded
                   
                    
                    if(numb_blocks == 0)                     
                        command3 = char(strcat('g711demo.exe', {' '}, law ,{' '},num2str(convertion),...
                        {' '},pcm_encode, {' '}, pcm_decode, {' '}, num2str(block_size), {' '}, num2str(first_block)));
                        [~,cmdout] = system(command3);
                    else
                        command4 = char(strcat('g711demo.exe', {' '}, law ,{' '},num2str(convertion),...
                        {' '},pcm_encode, {' '}, pcm_decode, {' '}, num2str(block_size), {' '}, num2str(first_block), num2str(numb_blocks)));
                        [~,cmdout] = system(command4);
                    end
                    
                   % fid= fopen(pcm_decode,'r');                   
                   % result = fread(fid,inf,'int16');
                   % fclose(fid);         
                                                                  
                    end
                                                                            
                   % result2 = result';

                   file_name2 = strcat(name,'(PLR-', num2str(theo_pack_loss_rate), ';BurstR-', num2str(BurstR),';PLC)');
                   % file_save = strcat(file_name2, '.wav');
                   %  audiowrite(file_save, result2, fs);                   
               
                    
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
                    {' '}, name,'(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ';PLC).wav', ...
                    {' '}, name, '(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ';PLC).wav', ...
                    '-PLC')); 
                    [~,cmdout] = system(command6);
                                                                                    
                    command7 = char(strcat('p862.exe', {' '}, name ,'.wav',...
                    {' '},name,'(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ';PLC).wav',' +', num2str(fs)));
                    [~,cmdout] = system(command7);
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


