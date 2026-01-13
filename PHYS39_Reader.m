%% Add Chronux to search path
% Download here: http://chronux.org/
% (version 2.12)
addpath(genpath('C:\chronux_2_12'))

%% Parameters
fs = 20000;          % Sampling rate (Hz)
T  = 2;              % Acquisition duration (s)
Ns = fs * T;         % Total number of frames

device = 'Dev1';     % Configure DAQ (data acquisition device) in NI MAX
ch1 = 'ai0';         % Signals you want to measure should feed into DAQ here
ch2 = 'ai1';

%% Create DAQ object
d = daq("ni");
d.Rate = fs;

addinput(d, device, ch1, "Voltage");
addinput(d, device, ch2, "Voltage");

%% Acquire data
disp('Acquiring data...');
data = read(d, Ns, "OutputFormat", "Matrix");
disp('Done.');

%% Split channels
t = (0:Ns-1)'/fs;
x1 = data(:,1);
x2 = data(:,2);

%% Quick sanity check
figure;
subplot(2,1,1)
plot(t, x1)
ylabel('V'); title('Signal 1')

subplot(2,1,2)
plot(t, x2)
ylabel('V'); xlabel('Time (s)')
title('Signal 2')

%% Remove DC offset
x1 = detrend(x1, 'constant');
x2 = detrend(x2, 'constant');

%% Optional: band-limit to avoid garbage
bp = designfilt('bandpassiir', ...
    'FilterOrder', 6, ...
    'HalfPowerFrequency1', 1, ...
    'HalfPowerFrequency2', fs/2-100, ...
    'SampleRate', fs);

x1 = filtfilt(bp, x1);
x2 = filtfilt(bp, x2);

%% Chronux parameters

% T = data window length (seconds)
% W = half-bandwidth of spectral smoothing (Hz)
% TW = time–bandwidth product (dimensionless)
% K = number of tapers used

params.Fs = fs;
params.tapers = [3 5];    % [TW K] — reasonable default
params.pad = 0;
params.err = [2 0.05];    % Jackknife, 95% CI
params.trialave = 0;      % Single trial

fpass = [0 5000];         % Frequency range of interest

%% Power spectral density
[S1, f] = mtspectrumc(x1, params);
[S2, ~] = mtspectrumc(x2, params);

figure;
plot(f, 10*log10(S1), 'LineWidth', 1.2); hold on;
plot(f, 10*log10(S2), 'LineWidth', 1.2);
xlim(fpass)
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
legend('Signal 1','Signal 2')
title('Multi-taper Power Spectrum')


%% Coherence and phase
[C, phi, S12, S1, S2, f] = coherencyc(x1, x2, params);

figure;
subplot(2,1,1)
plot(f, C, 'k', 'LineWidth', 1.2)
xlim(fpass)
ylabel('Coherence')
title('Coherence')

subplot(2,1,2)
plot(f, phi, 'k', 'LineWidth', 1.2)
xlim(fpass)
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')

