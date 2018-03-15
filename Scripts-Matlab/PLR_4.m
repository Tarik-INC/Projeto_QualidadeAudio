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
   
    vad(file_open,'pitch','arquivo_VAD');
    [x,fs] = audioread(file_open);
    x = x';
    
    fileVAD = fopen('arquivo_VAD');
    frames = fscanf(fileVAD, '%d'); 
    fclose(fileVAD);
    
    shift_frame = 10;
    
    fram_segm = 1; % seleciona os intervalos de frames(segmento de voz)
    
   
    orig_total = length(x); % quantidade total de amostras no audio original
  
    og_segm = 1;
    x2 = [];
    x3 = [];
    
    init_sample = (frames(fram_segm)*shift_frame*fs/1000);   % onde começa a amostra com segementos de voz
    end_sample = (frames(fram_segm+1)*shift_frame*fs/1000);  %onde termina a amostra

    while og_segm <= orig_total
         
        if( og_segm >= init_sample && og_segm <= end_sample)
            x2 = [x2 x(og_segm)]; 
          
        else 
            x3 = [x3 x(og_segm)];
        end
           
        og_segm = og_segm +1;
        
        if(og_segm > end_sample)
            fram_segm = fram_segm +1;
            
             if(fram_segm < size(frames,1))              
                 init_sample = (frames(fram_segm)*shift_frame*fs/1000);   % onde começa a amostra com segementos de voz
                 end_sample = (frames(fram_segm+1)*shift_frame*fs/1000);  %onde termina a amostra              
            end
        end
               
    end
    
   % audiowrite('teste.wav',x2,fs);
              
    mean_MOS = zeros(4,8);
    frq_good  = zeros(4,8); % frequencia de pacotes bons
    sd_MOS = zeros(4,8);
 %   pr_value = zeros(4,8);
    p_value = zeros(4,8);
    r_value = zeros(4,8);
    
    total_packs = length(x2);

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

                    x4 = x2 .* packets; %x4 e o vetor com degradacoes
              
                    %apos a degradacao 
                    result  = zeros(1,orig_total);
                    og_segm = 1;
                    ind_speech =1; %indice segmento de voz
                    ind_silence = 1; %segmento de silencio
                    fram_segm = 1;
                    
                    init_sample = (frames(fram_segm)*shift_frame*fs/1000);   % onde começa a amostra com segementos de voz
                    end_sample = (frames(fram_segm+1)*shift_frame*fs/1000);  %onde termina a amostra

                    while og_segm <= orig_total

                      if( og_segm >= init_sample && og_segm <= end_sample)
                            result(og_segm) =  x4(ind_speech); 
                             ind_speech = ind_speech + 1;
                      else 
                            result(og_segm) =  x3(ind_silence);
                            ind_silence = ind_silence + 1;
                      end
                        
                      og_segm = og_segm +1;
                      
                        if(og_segm > end_sample)
                            fram_segm = fram_segm +1;
                            
                            if(fram_segm < size(frames,1))     
                                 init_sample = (frames(fram_segm)*shift_frame*fs/1000);   % onde começa a amostra com segementos de voz
                                 end_sample = (frames(fram_segm+1)*shift_frame*fs/1000);  %onde termina a amostra                           
                            end
                        end

                      
                    end
                                                                            
                    result2 = result';

                    file_name2 = strcat(name,'(PLR-', num2str(theo_pack_loss_rate), ';BurstR-', num2str(BurstR), ').wav' );
                    file_save = strcat('', file_name2);
                    audiowrite(file_save, result2, fs);


                    command = char(strcat('p862.exe', {' '}, name ,'.wav',...
                    {' '},name,'(PLR-', num2str(PLR), ';BurstR-', num2str(BurstR), ').wav',' +', num2str(fs)));
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
    
end
packets
theo_pack_loss_rate = p / (p+r);
act_pack_loss_rate = 1 - received_packs/total_packs;


