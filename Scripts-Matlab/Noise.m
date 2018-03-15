
clc 
clear

file_names = ['m_25_en_c_se01'];
file_names = regexp(file_names,',','split');


for w=1:length(file_names)
    
    name = char(file_names(w));
      
    file_open = strcat('origFiles\', name, '.wav');
    [x,fs] = audioread(file_open); 
        
    repeat = 100; %variavel para controlar o nro de repeticoes
    
   noises = ['White,Violet,Pink,Blue,Red']; % Pink,Blue,Red,Violet'];
   noises = regexp(noises,',','split');
   
           % inicializa vetor vazio
          
           Mean_MOS_White = zeros(1,11);
           Mean_MOS_Pink = zeros(1,11);
           Mean_MOS_Red = zeros(1,11);
           Mean_MOS_Violet = zeros(1,11);
           Mean_MOS_Blue = zeros(1,11);
           sd_MOS_White = zeros(1,11);
           sd_MOS_Red = zeros(1,11);
           sd_MOS_Violet = zeros(1,11);
           sd_MOS_Pink = zeros(1,11); 
           sd_MOS_Blue = zeros(1,11);
          
       for j =1:length(noises)
               
           Sum_MOS = zeros(1,11);
           Sum_MOS_var = zeros(1,11);
           noise = char(noises(j));
           
           for k =1:repeat

                s = 1; %controla indice do soma MOS
               for snr = [ 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
                        
                    if strcmp(noise,'White')


                        result = awgn(x,snr);

                    else if  strcmp(noise,'Pink')

                            Ps = 10*log10(std(x).^2);       % signal power, dBV^2
                            Pn = Ps - snr;                  % noise power, dBV^2
                            Pn = 10^(Pn/10);                % noise power, V^2
                            sigma = sqrt(Pn);               % noise RMS, V

                            n = sigma*pinknoise(length(x));         % pink noise generation
                            n = n';                                       
                            result = x + n;                         % signal + noise mixture

                    else if  strcmp(noise,'Blue')

                            Ps = 10*log10(std(x).^2);       
                            Pn = Ps - snr;                  
                            Pn = 10^(Pn/10);                
                            sigma = sqrt(Pn);              

                            n = sigma*bluenoise(length(x));         
                            n = n';                                       
                            result = x + n;                         

                   else if strcmp(noise,'Red')

                            Ps = 10*log10(std(x).^2);       
                            Pn = Ps - snr;                  
                            Pn = 10^(Pn/10);               
                            sigma = sqrt(Pn);               
                            n = sigma*rednoise(length(x));          
                            n = n';                                       
                            result = x + n;                        

                   else if strcmp(noise,'Violet')

                            Ps = 10*log10(std(x).^2);       
                            Pn = Ps - snr;                
                            Pn = 10^(Pn/10);                
                            sigma = sqrt(Pn);             

                            n = sigma*violetnoise(length(x));        
                            n = n';                                       
                            result = x + n;                         
                        end

                        end

                        end

                        end

                    end

                        file_name2 = strcat( name,'(Noise-', noise, ';snr-', num2str(snr), ')' );
                        file_save = strcat( file_name2,'.wav' );
                        audiowrite(file_save, result, fs);

                        command = char(strcat('p862.exe', {' '}, name ,'.wav',...
                        {' '},file_save,' +', num2str(fs)));
                        [~,cmdout] = system(command);
                        pos = strfind(cmdout, 'PESQ_MOS');
                        MOS_valor1 = str2num(cmdout(pos+10:pos+15));
                        disp(sprintf('PESQ_MOS = %0.3f ',MOS_valor1));

                       % Sum_MOS = Sum_MOS + MOS_valor1; 

                        
                       Sum_MOS(s) = Sum_MOS(s) + MOS_valor1;
                       Sum_MOS_var(s) = Sum_MOS_var(s) + MOS_valor1.^2; %somatorio utilizado na  calculo da variança
                       s = s +1;

               end
           end
       

                    if strcmp(noise,'White')

                        for iw = 1:11
                            Mean_MOS_White(iw) = Sum_MOS(iw)/repeat;
                            sd_MOS_White(iw) = sqrt((Sum_MOS_var(iw) - (repeat*Mean_MOS_White(iw).^2))/(repeat-1));
                        end

                    else if strcmp(noise,'Pink');

                        for iw = 1:11
                            Mean_MOS_Pink(iw) = Sum_MOS(iw)/repeat;
                            sd_MOS_Pink(iw) = sqrt((Sum_MOS_var(iw) - (repeat*Mean_MOS_Pink(iw).^2))/(repeat-1));
                        end

               
                    else if strcmp(noise,'Blue');

                        for iw = 1:11
                            Mean_MOS_Blue(iw) = Sum_MOS(iw)/repeat;
                            sd_MOS_Blue(iw) = sqrt((Sum_MOS_var(iw) - (repeat*Mean_MOS_Blue(iw).^2))/(repeat-1));
                        end

                 

                    else if strcmp(noise,'Red');

                        for iw = 1:11
                            Mean_MOS_Red(iw) = Sum_MOS(iw)/repeat;
                            sd_MOS_Red(iw) = sqrt((Sum_MOS_var(iw) - (repeat*Mean_MOS_Red(iw).^2))/(repeat-1));
                        end


                    else if strcmp(noise,'Violet');

                        for iw = 1:11
                            Mean_MOS_Violet(iw) = Sum_MOS(iw)/repeat;
                            sd_MOS_Violet(iw) = sqrt((Sum_MOS_var(iw) - (repeat*Mean_MOS_Violet(iw).^2))/(repeat-1));
                        end
                        
                        end
                        end
                        end
                        end
                    end
              
       end

                    %{
                   Mean_MOS = (Sum_MOS/repeat);

                   Var_MOS = (Sum_MOS.^2 - repeat*Mean_MOS.^2)/(repeat-1);

                   header = 'Media -> Variança';
                   fid = fopen('MOS_result', 'w');
                   fprintf(fid, [header '\r\n']);
                   fclose(fid);

                   fid = fopen('MOS_Result.txt','a');
                   fprintf(fid, [file_name2 ' :' '\r\n']);
                   fprintf(fid, [num2str(Mean_MOS) ' ' num2str(Mean_MOS) '\r\n\r\n']);
                   fclose(fid);
                    %}
end
        

