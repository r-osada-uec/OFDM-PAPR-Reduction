% run_papr_test.m
% 前提：
% 5G Waveform GeneratorからExport to Workspace済み
% Workspace内に waveform, Fs, cfgDL が存在すること
%
% waveform : 5G NR複素IQ波形
% Fs       : サンプルレート [Hz]
% cfgDL    : 5G NR Downlink構成

%% 1. 条件設定
clipLevel_dB = 8;

% チャネル帯域幅 [Hz]
% 例：10 MHz波形なら 10e6
% Generatorで作ったChannel Bandwidthに合わせて変更してください
channelBW = 100e6;

%% 2. 元波形のPAPR計算
papr_org = calcPAPR(waveform);
fprintf("Original PAPR = %.2f dB\n", papr_org);

%% 3. 単純クリッピング
waveform_clip = paprClip(waveform, clipLevel_dB);

% RMS電力を元波形とそろえる
waveform_clip = waveform_clip / rms(waveform_clip(:)) * rms(waveform(:));

papr_clip = calcPAPR(waveform_clip);
fprintf("Hard clipped PAPR = %.2f dB\n", papr_clip);

%% 4. クリッピング後フィルタリング
waveform_clip_filt = bandLimitAfterClip(waveform_clip, Fs, channelBW);

% RMS電力を元波形とそろえる
waveform_clip_filt = waveform_clip_filt / rms(waveform_clip_filt(:)) * rms(waveform(:));

papr_clip_filt = calcPAPR(waveform_clip_filt);
fprintf("Clipped + filtered PAPR = %.2f dB\n", papr_clip_filt);

%% 5. Analyzer用構造体：元波形
waveform_org_for_analyzer = struct();
waveform_org_for_analyzer.waveform = waveform;
waveform_org_for_analyzer.fs = Fs;
waveform_org_for_analyzer.configuration = cfgDL;

%% 6. Analyzer用構造体：単純クリッピング波形
waveform_clip_for_analyzer = struct();
waveform_clip_for_analyzer.waveform = waveform_clip;
waveform_clip_for_analyzer.fs = Fs;
waveform_clip_for_analyzer.configuration = cfgDL;

%% 7. Analyzer用構造体：クリッピング＋フィルタリング波形
waveform_clip_filt_for_analyzer = struct();
waveform_clip_filt_for_analyzer.waveform = waveform_clip_filt;
waveform_clip_filt_for_analyzer.fs = Fs;
waveform_clip_filt_for_analyzer.configuration = cfgDL;

%% 8. 結果表示
disp("Analyzer用構造体を作成しました。");

%% 9. 確認
disp("---- Variable check ----");
fprintf("Fs = %.3f MHz\n", Fs/1e6);
fprintf("clipLevel_dB = %.1f dB\n", clipLevel_dB);
fprintf("channelBW = %.3f MHz\n", channelBW/1e6);