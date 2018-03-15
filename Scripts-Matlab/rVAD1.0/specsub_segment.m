function [ss,snr,gg,tt,ff,zo]=specsub_segment(si,fsz,pp)
%SPECSUB performs speech enhancement using spectral subtraction [SS,ZO]=(S,FSZ,P)
%
% Usage: (1) y=specsub(x,fs);   % enhance the speech using default parameters
%
% Inputs:
%   si      input speech signal
%   fsz     sample frequency in Hz
%           Alternatively, the input state from a previous call (see below)
%   pp      algorithm parameters [optional]
%
% Outputs:
%   ss        output enhanced speech
%   gg(t,f,i) selected time-frequency values (see pp.tf below)
%   tt        centre of frames (in seconds)
%   ff        centre of frequency bins (in Hz)
%   zo        output state (or the 2nd argument if gg,tt,ff are omitted)
%
% The algorithm operation is controlled by a small number of parameters:
%
%        pp.of          % overlap factor = (fft length)/(frame increment) [2]
%        pp.ti          % desired frame increment [0.016 seconds]
%        pp.ri          % set to 1 to round ti to the nearest power of 2 samples [0]
%        pp.g           % subtraction domain: 1=magnitude, 2=power [1]
%        pp.e           % gain exponent [1]
%        pp.am          % max oversubtraction factor [3]
%        pp.b           % max noise attenutaion in power domain [0.01]
%        pp.al          % SNR for oversubtraction=am (set this to Inf for fixed a) [-5 dB]
%        pp.ah          % SNR for oversubtraction=1 [20 dB]
%        pp.ne          % noise estimation: 0=min statistics, 1=MMSE [0]
%        pp.bt          % threshold for binary gain or -1 for continuous gain [-1]
%        pp.mx          % input mixture gain [0]
%        pp.gh          % maximum gain for noise floor [1]
%        pp.rf          % round output signal to an exact number of frames [0]
%        pp.tf          % selects time-frequency planes to output in the gg() variable ['g']
%                           'i' = input power spectrum
%                           'I' = input complex spectrum
%                           'n' = noise power spectrum
%                           'g' = gain
%                           'o' = output power spectrum
%                           'O' = output complex spectrum
%
% Following [1], the magnitude-domain gain in each time-frequency bin is given by
%                          gain=mx+(1-mx)*max((1-(a*N/X)^(g/2))^(e/g),min(gh,(b*N/X)^(e/2)))
% where N and X are the powers of the noise and noisy speech respectively.
% The oversubtraction factor varies linearly between a=am for a frame SNR of al down to
% a=1 for a frame SNR of ah. To obtain a fixed value of a for all values of SNR, set al=Inf.
% Common exponent combinations are:
%                      g=1  e=1    Magnitude Domain spectral subtraction
%                      g=2  e=1    Power Domain spectral subtraction
%                      g=2  e=2    Wiener filtering
% Many authors use the parameters alpha=a^(g/2), beta=b^(g/2) and gamma2=e/g instead of a, b and e
% but this increases interdependence amongst the parameters.
% If bt>=0 then the max(...) expression above is thresholded to become 0 or 1.
%
% In addition it is possible to specify parameters for the noise estimation algorithm
% which implements reference [2] or [3] according to the setting of pp.ne
%
% Minimum statistics noise estimate [2]: pp.ne=0 
%        pp.taca      % (11): smoothing time constant for alpha_c [0.0449 seconds]
%        pp.tamax     % (3): max smoothing time constant [0.392 seconds]
%        pp.taminh    % (3): min smoothing time constant (upper limit) [0.0133 seconds]
%        pp.tpfall    % (12): time constant for P to fall [0.064 seconds]
%        pp.tbmax     % (20): max smoothing time constant [0.0717 seconds]
%        pp.qeqmin    % (23): minimum value of Qeq [2]
%        pp.qeqmax    % max value of Qeq per frame [14]
%        pp.av        % (23)+13 lines: fudge factor for bc calculation  [2.12]
%        pp.td        % time to take minimum over [1.536 seconds]
%        pp.nu        % number of subwindows to use [3]
%        pp.qith      % Q-inverse thresholds to select maximum noise slope [0.03 0.05 0.06 Inf ]
%        pp.nsmdb     % corresponding noise slope thresholds in dB/second   [47 31.4 15.7 4.1]
%
% MMSE noise estimate [3]: pp.ne=1 
%        pp.tax      % smoothing time constant for noise power estimate [0.0717 seconds](8)
%        pp.tap      % smoothing time constant for smoothed speech prob [0.152 seconds](23)
%        pp.psthr    % threshold for smoothed speech probability [0.99] (24)
%        pp.pnsaf    % noise probability safety value [0.01] (24)
%        pp.pspri    % prior speech probability [0.5] (18)
%        pp.asnr     % active SNR in dB [15] (18)
%        pp.psini    % initial speech probability [0.5] (23)
%        pp.tavini   % assumed speech absent time at start [0.064 seconds]
%
% If convenient, you can call specsub in chunks of arbitrary size. Thus the following are equivalent:
%
%                   (a) y=specsub(s,fs);
%
%                   (b) [y1,z]=specsub(s(1:1000),fs);
%                       [y2,z]=specsub(s(1001:2000),z);
%                       y3=specsub(s(2001:end),z);
%                       y=[y1; y2; y3];
%
% If the number of output arguments is either 2 or 5, the last partial frame of samples will
% be retained for overlap adding with the output from the next call to specsub().
%
% See also ssubmmse() for an alternative gain function
%
% Refs:
%    [1] M. Berouti, R. Schwartz and J. Makhoul
%        Enhancement of speech corrupted by acoustic noise
%        Proc IEEE ICASSP, 1979, 4, 208-211
%    [2] Rainer Martin.
%        Noise power spectral density estimation based on optimal smoothing and minimum statistics.
%        IEEE Trans. Speech and Audio Processing, 9(5):504-512, July 2001.
%    [3] Gerkmann, T. & Hendriks, R. C.
%        Unbiased MMSE-Based Noise Power Estimation With Low Complexity and Low Tracking Delay
%        IEEE Trans Audio, Speech, Language Processing, 2012, 20, 1383-1393

%      Copyright (C) Mike Brookes 2004
%      Version: $Id: specsub.m 1720 2012-03-31 17:17:31Z dmb $
%
%   VOICEBOX is a MATLAB toolbox for speech processing.
%   Home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   http://www.gnu.org/copyleft/gpl.html or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if numel(si)>length(si)
    error('Input speech signal must be a vector not a matrix');
end
if isstruct(fsz)
    fs=fsz.fs;
    qq=fsz.qq;
    qp=fsz.qp;
    ze=fsz.ze;
    s=zeros(length(fsz.si)+length(si(:)),1); % allocate space for speech
    s(1:length(fsz.si))=fsz.si;
    s(length(fsz.si)+1:end)=si(:);
else
    fs=fsz;     % sample frequency
    s=si(:);
    % default algorithm constants

    qq.of=2;   % overlap factor = (fft length)/(frame increment)
    qq.ti=16e-3;   % desired frame increment (16 ms)
    qq.ri=0;       % round ni to the nearest power of 2
    qq.g=1;        % subtraction domain: 1=magnitude, 2=power
    qq.e=1;        % gain exponent
    qq.am=3;      % max oversubtraction factor
    qq.b=0.01;      % noise floor
    qq.al=-5;       % SNR for maximum a (set to Inf for fixed a)
    qq.ah=20;       % SNR for minimum a
    qq.bt=-1;       % suppress binary masking
    qq.ne=0;        % noise estimation: 0=min statistics, 1=MMSE [0]
    qq.mx=0;        % no input mixing
    qq.gh=1;        % maximum gain
    qq.tf='g';      % output the gain time-frequency plane by default
    qq.rf=0;
    if nargin>=3 && ~isempty(pp)
        qp=pp;      % save for estnoisem call
        qqn=fieldnames(qq);
        for i=1:length(qqn)
            if isfield(pp,qqn{i})
                qq.(qqn{i})=pp.(qqn{i});
            end
        end
    else
        qp=struct;  % make an empty structure
    end
end
% derived algorithm constants
if qq.ri
    ni=pow2(nextpow2(qq.ti*fs*sqrt(0.5)));
else
    ni=round(qq.ti*fs);    % frame increment in samples
end
tinc=ni/fs;          % true frame increment time
tf=qq.tf;
rf=qq.rf || nargout==3 || nargout==6;            % round down to an exact number of frames
ne=qq.ne;           % noise estimation: 0=min statistics, 1=MMSE [0]

% calculate power spectrum in frames

no=round(qq.of);                                   % integer overlap factor
nf=ni*no;           % fft length
w=sqrt(hamming(nf+1))'; w(end)=[]; % for now always use sqrt hamming window
w=w/sqrt(sum(w(1:ni:nf).^2));       % normalize to give overall gain of 1
if rf>0
    rfm='';                         % truncated input to an exact number of frames
else
    rfm='r';
end
[y,tt]=enframe(s,w,ni,rfm);
tt=tt/fs;                           % frame times
yf=rfft(y,nf,2);
yp=yf.*conj(yf);        % power spectrum of input speech
[nr,nf2]=size(yp);              % number of frames
ff=(0:nf2-1)*fs/nf;

if isstruct(fsz)
    ssv=fsz.ssv;
else
    ssv=zeros(ni*(no-1),1);             % dummy saved overlap
end

yp120=[yp(1:60,:); yp(nr-60+1:nr,:)];
ypf120=sum(yp120,2);
[ypfY,ypfI]=sort(ypf120);
dp=zeros(nr,nf2);
for idp=1:nr; 
    dp(idp,:)=yp120(ypfI(60),:);
end
snr=sum(sum(yp,2))/sum(yp120(ypfI(10),:))/nr
 
ss=si;

